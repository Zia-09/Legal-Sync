import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';

class BackupRestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ===============================
  // CREATE FULL BACKUP
  // ===============================
  Future<String> createFullBackup(String firmId) async {
    try {
      final Map<String, dynamic> backupData = {};
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Backup collections
      final collections = [
        'users',
        'lawyers',
        'clients',
        'cases',
        'appointments',
        'documents',
        'invoices',
        'time_entries',
        'deadlines',
        'staff',
        'firms',
        'notifications',
        'chats',
      ];

      for (final collectionName in collections) {
        try {
          final snapshot = await _db.collection(collectionName).get();
          backupData[collectionName] = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        } catch (e) {
          // Skip collections that don't exist
        }
      }

      // Upload to Firebase Storage
      final backupFileName = 'backups/$firmId/backup_$timestamp.json';
      final storageRef = _storage.ref().child(backupFileName);

      final backupJson = jsonEncode(backupData);
      await storageRef.putString(backupJson);

      // Log backup
      await _db.collection('backup_logs').add({
        'firmId': firmId,
        'backupPath': backupFileName,
        'timestamp': Timestamp.now(),
        'size': backupJson.length,
        'status': 'completed',
      });

      return backupFileName;
    } catch (e) {
      rethrow;
    }
  }

  // ===============================
  // CREATE CASE BACKUP
  // ===============================
  Future<String> createCaseBackup(String caseId, String firmId) async {
    try {
      final Map<String, dynamic> backupData = {};
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Get case data
      final caseDoc = await _db.collection('cases').doc(caseId).get();
      backupData['case'] = caseDoc.data();

      // Get associated documents
      final docs = await _db
          .collection('documents')
          .where('caseId', isEqualTo: caseId)
          .get();
      backupData['documents'] = docs.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      // Get time entries
      final entries = await _db
          .collection('time_entries')
          .where('caseId', isEqualTo: caseId)
          .get();
      backupData['time_entries'] = entries.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      // Get invoices
      final invoices = await _db
          .collection('invoices')
          .where('caseId', isEqualTo: caseId)
          .get();
      backupData['invoices'] = invoices.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      // Upload to Firebase Storage
      final backupFileName = 'backups/$firmId/case_${caseId}_$timestamp.json';
      final storageRef = _storage.ref().child(backupFileName);

      final backupJson = jsonEncode(backupData);
      await storageRef.putString(backupJson);

      return backupFileName;
    } catch (e) {
      rethrow;
    }
  }

  // ===============================
  // GET BACKUP LIST
  // ===============================
  Future<List<Map<String, dynamic>>> getBackupList(String firmId) async {
    try {
      final snapshot = await _db
          .collection('backup_logs')
          .where('firmId', isEqualTo: firmId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  // ===============================
  // RESTORE FROM BACKUP
  // ===============================
  Future<bool> restoreFromBackup(String firmId, String backupPath) async {
    try {
      // Download backup file
      final storageRef = _storage.ref().child(backupPath);
      final bytes = await storageRef.getData();
      if (bytes == null) {
        return false;
      }
      final backupJson = utf8.decode(bytes);
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Restore each collection
      final batch = _db.batch();

      for (final collectionName in backupData.keys) {
        final items = backupData[collectionName] as List;
        for (final item in items) {
          final docId = item['id'];
          final docData = Map<String, dynamic>.from(item)..remove('id');
          batch.set(
            _db.collection(collectionName).doc(docId),
            docData,
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();

      // Log restore
      await _db.collection('restore_logs').add({
        'firmId': firmId,
        'backupPath': backupPath,
        'timestamp': Timestamp.now(),
        'status': 'completed',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ===============================
  // DELETE BACKUP
  // ===============================
  Future<void> deleteBackup(String firmId, String backupId) async {
    try {
      final doc = await _db.collection('backup_logs').doc(backupId).get();
      if (doc.exists) {
        final backupPath = doc.data()?['backupPath'];
        if (backupPath != null) {
          await _storage.ref().child(backupPath as String).delete();
        }
      }

      await _db.collection('backup_logs').doc(backupId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // ===============================
  // SCHEDULE AUTO BACKUP
  // ===============================
  Future<void> scheduleAutoBackup(String firmId, String frequency) async {
    try {
      await _db.collection('backup_schedules').doc(firmId).set({
        'firmId': firmId,
        'frequency': frequency, // daily, weekly, monthly
        'lastBackup': Timestamp.now(),
        'nextBackup': _calculateNextBackupDate(frequency),
        'enabled': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ===============================
  // CALCULATE NEXT BACKUP DATE
  // ===============================
  Timestamp _calculateNextBackupDate(String frequency) {
    late DateTime nextDate;
    switch (frequency) {
      case 'daily':
        nextDate = DateTime.now().add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDate = DateTime.now().add(const Duration(days: 7));
        break;
      case 'monthly':
        nextDate = DateTime.now().add(const Duration(days: 30));
        break;
      default:
        nextDate = DateTime.now().add(const Duration(days: 7));
    }
    return Timestamp.fromDate(nextDate);
  }

  // ===============================
  // GET BACKUP STATUS
  // ===============================
  Future<Map<String, dynamic>> getBackupStatus(String firmId) async {
    try {
      final schedule = await _db
          .collection('backup_schedules')
          .doc(firmId)
          .get();

      if (!schedule.exists) {
        return {'status': 'no_schedule'};
      }

      return schedule.data() ?? {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
