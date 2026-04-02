import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/document_provider.dart';
import 'package:intl/intl.dart';

class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

    final clientAsync = ref.watch(currentClientProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 16),
            ),
          ),
        ),
        title: Text(
          'Recent Activity',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                 shape: BoxShape.circle,
               ),
               child: Icon(Icons.search, color: textColor, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: clientAsync.when(
        data: (client) {
          if (client == null) {
            return Center(
              child: Text(
                'User not found',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final docsAsync = ref.watch(documentsByClientProvider(client.clientId));

          return docsAsync.when(
            data: (documents) => _buildActivityList(
              documents,
              cardColor,
              textColor,
              subtitleColor,
              isDark,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)),
            ),
            error: (err, st) => Center(
              child: Text('Error: $err', style: TextStyle(color: textColor)),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
        error: (err, st) => Center(
          child: Text('Error: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFDC2626),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildActivityList(
    List documents,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    if (documents.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.history, color: subtitleColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group documents by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groupedDocs = <String, List>{
      'TODAY': [],
      'YESTERDAY': [],
      'LAST WEEK': [],
      'OLDER': [],
    };

    for (var doc in documents) {
      final docDate = DateTime(doc.uploadedAt.year, doc.uploadedAt.month, doc.uploadedAt.day);
      if (docDate == today) {
        groupedDocs['TODAY']!.add(doc);
      } else if (docDate == yesterday) {
        groupedDocs['YESTERDAY']!.add(doc);
      } else if (docDate.isAfter(weekAgo)) {
        groupedDocs['LAST WEEK']!.add(doc);
      } else {
        groupedDocs['OLDER']!.add(doc);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          ...groupedDocs.entries
              .where((e) => e.value.isNotEmpty)
              .expand((entry) => [
                    _buildSectionHeader(entry.key, subtitleColor),
                    const SizedBox(height: 16),
                    ...entry.value.map((doc) => _buildActivityItem(
                          doc.fileName ?? 'Document',
                          'Uploaded by ${doc.uploadedBy}',
                          _timeAgo(doc.uploadedAt),
                          _getIconForFileType(doc.fileType),
                          _getColorForFileType(doc.fileType),
                          cardColor,
                          textColor,
                          subtitleColor,
                          isDark,
                        )),
                    const SizedBox(height: 24),
                  ]),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  IconData _getIconForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_outlined;
      case 'doc':
      case 'docx':
      case 'word':
        return Icons.article_outlined;
      case 'xls':
      case 'xlsx':
      case 'excel':
        return Icons.table_view_outlined;
      default:
        return Icons.description;
    }
  }

  Color _getColorForFileType(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.blue;
      case 'doc':
      case 'docx':
      case 'word':
        return Colors.red;
      case 'xls':
      case 'xlsx':
      case 'excel':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildSectionHeader(String title, Color subtitleColor) {
    return Text(
      title,
      style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color iconColor, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: TextStyle(color: subtitleColor.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
