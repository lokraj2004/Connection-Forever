import 'package:cloud_firestore/cloud_firestore.dart';
import 'ClientIDinputScreen.dart';
import 'package:flutter/material.dart';
import 'display_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CFSlotAuthScreen extends StatelessWidget {
  final String slotKey;
  final String username;

  const CFSlotAuthScreen({
    required this.slotKey,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("CF Authenticator")),
      body: FutureBuilder<bool>(
        future: CFSlotAuthenticator.Authenticator(slotNumber: slotKey, username: username),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final authenticated = snapshot.data!;

          // Use microtask to delay navigation until after build completes
          Future.microtask(() async {
            if (authenticated) {
              // ✅ Save slotKey and username
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('slotKey', slotKey);
              await prefs.setString('username', username);

              // ✅ Navigate to success page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SensorDataPage(
                    slotKey: slotKey,
                    username: username,
                  ),
                ),
              );
            } else {
              // ❌ Navigate to retry page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => ClientIDInputScreen()),
                    (route) => false,
              );
            }
          });

          // Temporary UI while navigation is pending
          return Center(
            child: Text(
              authenticated
                  ? "✅ Authenticated! Redirecting..."
                  : "❌ Authentication failed. Redirecting...",
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}


class CFSlotAuthenticator {
  /// Verifies if the username is valid for the given slot.
  /// Returns true if authenticated, false if username mismatch or missing.
  static Future<bool> Authenticator({
    required String slotNumber,  // e.g., "slot3"
    required String username,
  }) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('slots')
          .doc('activeSlots')
          .get();

      if (!docSnapshot.exists) {
        print("activeSlots document does not exist.");
        return false;
      }

      final data = docSnapshot.data();
      if (data == null || !data.containsKey(slotNumber)) {
        print("Slot $slotNumber not found in activeSlots.");
        return false;
      }

      final slotData = data[slotNumber];
      if (slotData == null || !(slotData is Map) || !slotData.containsKey('username')) {
        print("Slot $slotNumber has no username assigned.");
        return false;
      }

      final storedUsername = slotData['username'];
      if (storedUsername == username) {
        print("Authentication successful.");
        return true;
      } else {
        print("Username mismatch: expected $storedUsername, got $username.");
        return false;
      }
    } catch (e) {
      print("Error during authentication check: $e");
      return false;
    }
  }
}
