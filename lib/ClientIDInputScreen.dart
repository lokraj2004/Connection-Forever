import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'slot_claiming_screen.dart';
import 'package:lottie/lottie.dart';

class ClientIDInputScreen extends StatefulWidget {
  @override
  _ClientIDInputScreenState createState() => _ClientIDInputScreenState();
}

class _ClientIDInputScreenState extends State<ClientIDInputScreen> with SingleTickerProviderStateMixin
 {
  final TextEditingController _clientIDController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _validateAndProceed() async {
    final clientID = _clientIDController.text.trim();
    final username = _usernameController.text.trim();

    if (clientID.isEmpty || username.isEmpty) {
      setState(() {
        _errorText = "Please enter both Client ID and Username.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('clientIDs')
          .doc(clientID)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorText =
          "Admin not yet generated Client ID or Client ID node is not there.";
        });
      } else {
        // ✅ Proceed to next screen with both values
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessScreen(
              clientID: clientID,
              username: username,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorText = "Error: ${e.toString()}";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _clientIDController.dispose();
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Client ID Pairing"),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                "Enter your Client ID and Username to pair with CT:",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              TextField(
                controller: _clientIDController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: "Client ID",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),

                ),
                maxLength: 6,
              ),
              SizedBox(height: 15),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),

                ),
              ),
              SizedBox(height: 20),
              if (_errorText != null)
                Text(
                  _errorText!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.6),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        textStyle: TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _validateAndProceed,
                      child: Text("Validate & Continue"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final String clientID;
  final String username;

  const SuccessScreen({required this.clientID, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Client Validated"),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🎉 Lottie Success Animation
              Lottie.asset(
                'assets/animations/Verified.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              SizedBox(height: 20),
              Text(
                "Client ID: '$clientID'\nUsername: '$username'\nValidation Successful!",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(Icons.arrow_forward),
                label: Text("Proceed to Claim Slot"),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SlotClaimingScreen(
                        clientID: clientID,
                        username: username,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

