import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_db_service.dart';
import 'firestore_service.dart';
import 'sync_service.dart';

/// Central gate for all cloud backup operations.
///
/// Dual-persistence: saves to BOTH SharedPreferences AND SQLite app_config
/// table so the preference survives even if one storage layer fails.
///
/// When [isBackupEnabled] is false:
///   - Scan data, habits, face images → LOCAL ONLY (SQLite)
///   - Firestore only receives: `users` + subscription writes
///
/// When [isBackupEnabled] is true:
///   - Everything syncs to Firestore via SyncService
///
/// Usage:
///   if (!BackupPreferenceService().isBackupEnabled) return;
class BackupPreferenceService {
  static final BackupPreferenceService _instance =
      BackupPreferenceService._internal();
  factory BackupPreferenceService() => _instance;
  BackupPreferenceService._internal();

  static const _keyEnabled      = 'backup_enabled_v1';
  static const _keyConsentShown = 'backup_consent_shown_v1';

  SharedPreferences? _prefs;

  // In-memory cache — set after init()
  bool _backupEnabled  = false;
  bool _consentShown   = false;
  bool _initialized    = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Must be called once at app startup.
  /// Reads from SharedPreferences first, then cross-checks SQLite config.
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;

    // Read from SharedPreferences
    final prefEnabled = prefs.getBool(_keyEnabled);
    final prefConsent = prefs.getBool(_keyConsentShown);

    // Cross-check with SQLite config (authoritative on conflicts)
    try {
      final db = LocalDbService();
      final dbEnabled = await db.getConfig(_keyEnabled);
      final dbConsent = await db.getConfig(_keyConsentShown);

      // SQLite is the authoritative source if it has data
      if (dbEnabled != null) {
        _backupEnabled = dbEnabled == 'true';
        // Sync back to prefs in case they diverged
        await prefs.setBool(_keyEnabled, _backupEnabled);
      } else if (prefEnabled != null) {
        _backupEnabled = prefEnabled;
        // Sync to SQLite
        await db.setConfig(_keyEnabled, _backupEnabled.toString());
      }

      if (dbConsent != null) {
        _consentShown = dbConsent == 'true';
        await prefs.setBool(_keyConsentShown, _consentShown);
      } else if (prefConsent != null) {
        _consentShown = prefConsent;
        await db.setConfig(_keyConsentShown, _consentShown.toString());
      }
    } catch (e) {
      // SQLite not ready yet — fall back to prefs values
      _backupEnabled = prefEnabled ?? false;
      _consentShown  = prefConsent ?? false;
      debugPrint('BackupPreferenceService.init: SQLite fallback ($e)');
    }

    _initialized = true;
    debugPrint(
      'BackupPreferenceService: init done — '
      'backup=$_backupEnabled, consentShown=$_consentShown',
    );
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  /// Whether cloud backup is currently enabled. Defaults to false.
  bool get isBackupEnabled => _initialized ? _backupEnabled : false;

  /// Whether the user has already seen and confirmed the backup consent screen.
  bool get hasShownConsent => _initialized ? _consentShown : false;

  // ── Setters ──────────────────────────────────────────────────────────────

  /// Enable or disable cloud backup.
  /// Writes to SharedPreferences, SQLite app_config, AND Firestore user doc.
  Future<void> setBackupEnabled(bool value) async {
    _backupEnabled = value;

    // 1. SharedPreferences
    await _prefs?.setBool(_keyEnabled, value);

    // 2. SQLite config
    try {
      await LocalDbService().setConfig(_keyEnabled, value.toString());
    } catch (e) {
      debugPrint('BackupPreferenceService.setBackupEnabled SQLite error: $e');
    }

    // 3. Firestore user doc (fire-and-forget — for analytics)
    _syncToFirestore({'backup_enabled': value});

    debugPrint('BackupPreferenceService: backup ${value ? 'ENABLED' : 'DISABLED'}');

    if (value) {
      // Push any locally stored scans to Firestore
      SyncService().syncPendingScans();
    }
  }

  /// Mark that the user has confirmed the consent screen (don't show again).
  /// Writes to SharedPreferences, SQLite app_config, AND Firestore user doc.
  Future<void> markConsentShown() async {
    _consentShown = true;

    // 1. SharedPreferences
    await _prefs?.setBool(_keyConsentShown, true);

    // 2. SQLite config
    try {
      await LocalDbService().setConfig(_keyConsentShown, 'true');
    } catch (e) {
      debugPrint('BackupPreferenceService.markConsentShown SQLite error: $e');
    }

    // 3. Firestore user doc (fire-and-forget — for analytics)
    _syncToFirestore({
      'backup_consent_shown': true,
      'backup_enabled': _backupEnabled,
      'backup_consent_at': DateTime.now().toIso8601String(),
    });

    debugPrint('BackupPreferenceService: consent screen confirmed & saved');
  }

  /// Internal helper: update Firestore user doc fields (fire-and-forget).
  void _syncToFirestore(Map<String, dynamic> fields) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;               // not logged in yet
    fields['backup_updated_at'] = DateTime.now().toIso8601String();
    FirestoreService()
        .updateUserBackupConfig(uid, fields)
        .catchError((e) => debugPrint('BackupPreferenceService Firestore sync error: $e'));
  }

  /// Reset everything (used on account delete / reset).
  Future<void> reset() async {
    _backupEnabled = false;
    _consentShown  = false;

    await _prefs?.remove(_keyEnabled);
    await _prefs?.remove(_keyConsentShown);
    try {
      await LocalDbService().deleteConfig(_keyEnabled);
      await LocalDbService().deleteConfig(_keyConsentShown);
    } catch (_) {}
  }
}
