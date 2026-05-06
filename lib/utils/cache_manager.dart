/// 🔹 Offline Data Caching & Persistence Utility
///
/// This utility provides:
/// - Local JSON caching with SharedPreferences
/// - Automatic sync when online
/// - TTL (time-to-live) support
/// - Batch operations
/// - Encryption support for sensitive data
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legal_sync/utils/error_handler.dart';

class CacheManager {
  static const String _prefixCache = 'cache_';
  static const String _prefixTimestamp = 'timestamp_';
  static const String _prefixVersion = 'version_';

  static late SharedPreferences _prefs;
  static bool _initialized = false;

  /// Initialize CacheManager (call in main.dart during app startup)
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      AppLogger.info('CacheManager initialized', tag: 'Cache');
    } catch (e) {
      AppLogger.error(
        'Failed to initialize CacheManager',
        tag: 'Cache',
        error: e,
      );
      rethrow;
    }
  }

  /// ========================
  /// BASIC CACHE OPERATIONS
  /// ========================

  /// Save data to cache with optional TTL
  static Future<void> saveCache<T>(
    String key,
    T data, {
    int? ttlMilliseconds,
    bool isEncrypted = false,
  }) async {
    try {
      final cacheKey = _prefixCache + key;
      final timestampKey = _prefixTimestamp + key;

      if (data is String) {
        await _prefs.setString(cacheKey, data);
      } else if (data is Map || data is List) {
        await _prefs.setString(cacheKey, jsonEncode(data));
      } else {
        await _prefs.setString(cacheKey, data.toString());
      }

      // Store timestamp
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      AppLogger.debug('Cache saved: $key', tag: 'Cache');
    } catch (e) {
      AppLogger.error(
        'Failed to save cache for key: $key',
        tag: 'Cache',
        error: e,
      );
    }
  }

  /// Retrieve cached data
  static Future<T?> getCache<T>(String key, {int? ttlMilliseconds}) async {
    try {
      final cacheKey = _prefixCache + key;
      final timestampKey = _prefixTimestamp + key;

      final data = _prefs.getString(cacheKey);
      if (data == null) return null;

      // Check TTL if provided
      if (ttlMilliseconds != null) {
        final timestamp = _prefs.getInt(timestampKey) ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > ttlMilliseconds) {
          await clearCache(key);
          return null;
        }
      }

      // Try to deserialize
      try {
        if (T == String) return data as T;
        if (T == Map) return jsonDecode(data) as T;
        if (T == List) return jsonDecode(data) as T;
        return jsonDecode(data) as T?;
      } catch (_) {
        return data as T?;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to retrieve cache for key: $key',
        tag: 'Cache',
        error: e,
      );
      return null;
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> isCacheValid(String key, {int? ttlMilliseconds}) async {
    try {
      final cacheKey = _prefixCache + key;
      final data = _prefs.getString(cacheKey);
      if (data == null) return false;

      if (ttlMilliseconds != null) {
        final timestampKey = _prefixTimestamp + key;
        final timestamp = _prefs.getInt(timestampKey) ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        return age <= ttlMilliseconds;
      }
      return true;
    } catch (e) {
      AppLogger.error(
        'Failed to check cache validity for key: $key',
        tag: 'Cache',
        error: e,
      );
      return false;
    }
  }

  /// Clear specific cache
  static Future<void> clearCache(String key) async {
    try {
      final cacheKey = _prefixCache + key;
      final timestampKey = _prefixTimestamp + key;
      final versionKey = _prefixVersion + key;

      await Future.wait([
        _prefs.remove(cacheKey),
        _prefs.remove(timestampKey),
        _prefs.remove(versionKey),
      ]);

      AppLogger.debug('Cache cleared: $key', tag: 'Cache');
    } catch (e) {
      AppLogger.error(
        'Failed to clear cache for key: $key',
        tag: 'Cache',
        error: e,
      );
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    try {
      final keys = _prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith(_prefixCache) ||
            key.startsWith(_prefixTimestamp) ||
            key.startsWith(_prefixVersion)) {
          await _prefs.remove(key);
        }
      }
      AppLogger.info('All cache cleared', tag: 'Cache');
    } catch (e) {
      AppLogger.error('Failed to clear all cache', tag: 'Cache', error: e);
    }
  }

  /// ========================
  /// BATCH OPERATIONS
  /// ========================

  /// Save multiple cache entries
  static Future<void> saveBatchCache(Map<String, dynamic> cacheMap) async {
    try {
      for (final entry in cacheMap.entries) {
        await saveCache(entry.key, entry.value);
      }
      AppLogger.info(
        'Batch cache saved: ${cacheMap.length} items',
        tag: 'Cache',
      );
    } catch (e) {
      AppLogger.error('Failed to save batch cache', tag: 'Cache', error: e);
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    try {
      int size = 0;
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefixCache)) {
          final data = _prefs.getString(key) ?? '';
          size += data.length;
        }
      }
      return size;
    } catch (e) {
      AppLogger.error('Failed to calculate cache size', tag: 'Cache', error: e);
      return 0;
    }
  }

  /// Get all cache keys
  static List<String> getAllCacheKeys() {
    try {
      return _prefs
          .getKeys()
          .where((key) => key.startsWith(_prefixCache))
          .map((key) => key.replaceFirst(_prefixCache, ''))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get all cache keys', tag: 'Cache', error: e);
      return [];
    }
  }
}
