import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceLimitExceededException implements Exception {
  final String message;
  DeviceLimitExceededException(this.message);
  @override
  String toString() => message;
}

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
  static const int _maxDevicesPerAccount = 2;

  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'v2db');

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

  // ── Register device + check limits ──────────────────────────────────────────

  /// Call this right after a new account is created or signed in.
  /// Throws DeviceLimitExceededException if limits are violated.
  Future<void> registerAndCheckDevice(String uid, DeviceInfo info) async {
    final deviceRef = _devices.doc(info.deviceId);
    final userRef = _users.doc(uid);

    // 1. Fetch current data
    final deviceDoc = await deviceRef.get();
    final userDoc = await userRef.get();

    List<String> deviceUids = [];
    if (deviceDoc.exists) {
      final data = deviceDoc.data() as Map<String, dynamic>;
      deviceUids = List<String>.from(data['uids'] ?? []);
    }

    List<String> userDevices = [];
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      userDevices = List<String>.from(data['active_devices'] ?? []);
    }

    // 2. Check Device Limit (Max 2 accounts per device)
    if (!deviceUids.contains(uid)) {
      if (deviceUids.length >= _maxAccountsPerDevice) {
        throw DeviceLimitExceededException(
            'This device has reached the maximum limit of $_maxAccountsPerDevice accounts.');
      }
      deviceUids.add(uid);
    }

    // 3. Check Account Limit (Max 2 devices per account)
    if (!userDevices.contains(info.deviceId)) {
      if (userDevices.length >= _maxDevicesPerAccount) {
        throw DeviceLimitExceededException(
            'Your account is already logged into $_maxDevicesPerAccount devices. Please log out from another device first.');
      }
      userDevices.add(info.deviceId);
    }

    // 4. Update Firestore in a batch
    final batch = _db.batch();

    batch.set(deviceRef, {
      'device_id': info.deviceId,
      'model': info.deviceModel,
      'os': info.deviceOs,
      'brand': info.brand,
      'account_count': deviceUids.length,
      'uids': deviceUids,
      'last_seen': FieldValue.serverTimestamp(),
      'first_seen': deviceDoc.exists
          ? (deviceDoc.data() as Map<String, dynamic>)['first_seen']
          : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'active_devices': userDevices,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ── Remove device on logout ────────────────────────────────────────────────

  Future<void> removeDevice(String uid) async {
    try {
      final info = await collectDeviceInfo();
      final userRef = _users.doc(uid);
      
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        List<String> userDevices = List<String>.from(data['active_devices'] ?? []);
        
        if (userDevices.contains(info.deviceId)) {
          userDevices.remove(info.deviceId);
          await userRef.update({
            'active_devices': userDevices,
          });
        }
      }
    } catch (e) {
      debugPrint('DeviceService.removeDevice error: $e');
    }
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
