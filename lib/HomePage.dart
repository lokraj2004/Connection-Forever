import 'package:flutter/material.dart';
import 'AppStartRouter.dart';
import 'BG_wrapper.dart';
import 'About&Help.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool showOptions = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToAbout() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AboutPage()));
  }
  void _showDevelopmentSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Development is in progress, maybe it is available in future updates.',
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Ensures background appears behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 12.0),
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              underline: SizedBox(), // removes underline
              icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.9)),
              onChanged: (String? value) {
                if (value == 'About') {
                  _navigateToAbout();
                } else if (value == 'Help') {
                  _showDevelopmentSnackbar(context);
                }
              },
              items: ['About', 'Help'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),

      body: BackgroundWrapper(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 120), // Pull content lower for AppBar space
                Center(
                  child: Text(
                    "Connection Forever",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black45,
                          offset: Offset(2, 2),
                        )
                      ],
                      letterSpacing: 1.5,
                    ),

                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    double scale = 1 + (_glowController.value * 0.05);
                    return Transform.scale(
                      scale: scale,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AppStartRouter()));
                        },
                        child: Text("Start"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          shadowColor: Colors.cyanAccent,
                          elevation: 15,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

