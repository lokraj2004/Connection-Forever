import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CFDataTracker {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  double _downloadedMB = 0.0; // locally accumulated download amount
  Timer? _timer;
  String? _slotKey; // e.g., "slot3"

  /// Starts the 3-minute tracking cycle
  Future<void> startTracking() async {
    final prefs = await SharedPreferences.getInstance();
    _slotKey = prefs.getString('slotKey');

    if (_slotKey == null) {
      print("No slotKey found. Cannot start tracking.");
      return;
    }

    _timer = Timer.periodic(Duration(minutes: 3), (_) => _syncDataToFirebase());
    print("Started CF tracking every 3 minutes.");
  }

  /// Call this method whenever data is downloaded to increment the local counter
  void addDownloadedData(double mb) {
    _downloadedMB += mb;
    print("Data added: $mb MB, Total: $_downloadedMB MB");
  }

  /// Pushes data to Firebase and resets counter
  Future<void> _syncDataToFirebase() async {
    if (_slotKey == null) return;

    final slotRef = _dbRef.child('track').child(_slotKey!);
    try {
      final snapshot = await slotRef.get();
      double currentVal = 0.0;

      if (snapshot.exists && snapshot.value != null) {
        currentVal = double.tryParse(snapshot.value.toString()) ?? 0.0;
      }

      double updatedVal = currentVal + _downloadedMB;

      await slotRef.set(updatedVal);
      print("Synced $_downloadedMB MB to $_slotKey. New total: $updatedVal MB");

      _downloadedMB = 0.0; // reset after syncing
    } catch (e) {
      print("Failed to sync to Firebase: $e");
    }
  }

  /// Stops tracking (call this when app closes)
  Future<void> stopTracking() async {
    _timer?.cancel();
    print("Stopping CF data tracking...");

    // Final sync before stopping
    if (_slotKey != null && _downloadedMB > 0.0) {
      await _syncDataToFirebase(); // Push remaining data to Firebase
    } else {
      print("No data to sync or slotKey is null.");
    }
  }

}
