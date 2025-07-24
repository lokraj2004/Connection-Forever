import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cf_auth_validator.dart';
import 'ClientIDinputScreen.dart';
import 'display_data.dart';
import 'package:lottie/lottie.dart';

class AppStartRouter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkStoredCredentials(context),
      builder: (context, snapshot) {
        return Scaffold(
          body: Center(
            child: Lottie.asset(
              'assets/animations/SandLoading.json', // Replace with your actual Lottie file path
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkStoredCredentials(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storedSlot = prefs.getString('slotKey');
    final storedUser = prefs.getString('username');

    if (storedSlot != null && storedUser != null) {
      bool auth = await CFSlotAuthenticator.Authenticator(
        slotNumber: storedSlot,
        username: storedUser,
      );

      if (auth) {
        Navigator.pushReplacement(
          context,
            MaterialPageRoute(
              builder: (_) => SensorDataPage(
                slotKey: storedSlot,
                username: storedUser,
              ),
            )
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ClientIDInputScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClientIDInputScreen()),
      );
    }
  }
}
