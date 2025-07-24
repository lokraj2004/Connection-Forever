import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'HomePage.dart';

class IntroPage1 extends StatefulWidget {
  @override
  _IntroPage1State createState() => _IntroPage1State();
}

class _IntroPage1State extends State<IntroPage1> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroPage2()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animations/SandLoading.json'), // Replace with your file
      ),
    );
  }
}

class IntroPage2 extends StatefulWidget {
  @override
  _IntroPage2State createState() => _IntroPage2State();
}

class _IntroPage2State extends State<IntroPage2> with TickerProviderStateMixin {
  bool showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showText = true;
      });

      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Logo.png', width: 300), // Your image
            SizedBox(height: 40),
            AnimatedOpacity(
              opacity: showText ? 1.0 : 0.0,
              duration: Duration(seconds: 1),
              child: Text(
                "Connection Forever",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
