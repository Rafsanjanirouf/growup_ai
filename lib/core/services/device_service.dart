import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Collected device information.
class DeviceInfo {
  final String deviceId;
  final String deviceModel;
  final String deviceOs;
  final String brand;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceModel,
    required this.deviceOs,
    required this.brand,
  });

  Map<String, dynamic> toMap() => {
        'device_id': deviceId,
        'device_model': deviceModel,
        'device_os': deviceOs,
        'brand': brand,
      };
}

/// ─────────────────────────────────────────────────────────────────────────────
/// DeviceService
/// Collects device fingerprint and enforces the "max 2 accounts per device"
/// policy. On violation, ALL accounts linked to that device are blocked.
/// ─────────────────────────────────────────────────────────────────────────────
class DeviceService {
  static final DeviceService _instance = DeviceService._();
  factory DeviceService() => _instance;
  DeviceService._();

  static const int _maxAccountsPerDevice = 2;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _devices => _db.collection('devices');
  CollectionReference get _users => _db.collection('users');

  // ── Collect device info ──────────────────────────────────────────────────────

  Future<DeviceInfo> collectDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return DeviceInfo(
          deviceId: info.id, // Android hardware ID
          deviceModel: info.model,
          deviceOs: 'Android ${info.version.release}',
          brand: info.brand,
        );
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return DeviceInfo(
          deviceId: info.identifierForVendor ?? 'unknown_ios',
          deviceModel: info.utsname.machine,
          deviceOs: 'iOS ${info.systemVersion}',
          brand: 'Apple',
        );
      }
    } catch (e) {
      debugPrint('DeviceService.collectDeviceInfo error: $e');
    }

    return const DeviceInfo(
      deviceId: 'unknown_device',
      deviceModel: 'Unknown',
      deviceOs: 'Unknown',
      brand: 'Unknown',
    );
  }

  // ── Register device + check for suspicious activity ──────────────────────────

  /// Call this right after a new account is created.
  /// Returns true if the account was blocked.
  Future<bool> registerAndCheckDevice(String uid, DeviceInfo info) async {
    try {
      final deviceRef = _devices.doc(info.deviceId);
      final deviceDoc = await deviceRef.get();

      List<String> uids = [];

      if (deviceDoc.exists) {
        final data = deviceDoc.data() as Map<String, dynamic>;
        uids = List<String>.from(data['uids'] ?? []);
      }

      // Add new uid if not already tracked
      if (!uids.contains(uid)) {
        uids.add(uid);
      }

      // Update device record
      await deviceRef.set({
        'device_id': info.deviceId,
        'model': info.deviceModel,
        'os': info.deviceOs,
        'brand': info.brand,
        'account_count': uids.length,
        'uids': uids,
        'last_seen': FieldValue.serverTimestamp(),
        'first_seen': deviceDoc.exists
            ? (deviceDoc.data() as Map<String, dynamic>)['first_seen']
            : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Check threshold
      if (uids.length > _maxAccountsPerDevice) {
        await _blockAllAccountsOnDevice(info.deviceId, uids);
        debugPrint('DeviceService: Suspicious activity — blocked ${uids.length} accounts on device ${info.deviceId}');
        return true; // blocked
      }

      return false; // not blocked
    } catch (e) {
      debugPrint('DeviceService.registerAndCheckDevice error: $e');
      return false;
    }
  }

  // ── Block all accounts linked to this device ─────────────────────────────────

  Future<void> _blockAllAccountsOnDevice(String deviceId, List<String> uids) async {
    final batch = _db.batch();
    final now = Timestamp.now();
    const reason = 'Multiple accounts detected from the same device. Suspicious activity policy violation.';

    for (final uid in uids) {
      batch.update(_users.doc(uid), {
        'block': true,
        'block_date': now,
        'block_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    // Mark device as flagged
    batch.update(_devices.doc(deviceId), {
      'flagged': true,
      'flagged_at': now,
      'block_reason': reason,
    });

    await batch.commit();
  }

  // ── Check if current user is blocked ─────────────────────────────────────────

  Future<bool> isUserBlocked(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      return data['block'] == true;
    } catch (e) {
      debugPrint('DeviceService.isUserBlocked error: $e');
      return false;
    }
  }
}
