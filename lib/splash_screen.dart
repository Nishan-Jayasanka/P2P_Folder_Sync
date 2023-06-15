import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'permission_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..addListener(() {
        if (_animationController.isCompleted) {
          navigateToHomeScreen();
        }
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              PermissionScreen()), // Push the home screen route
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 240, 248),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animationController.drive(
                Tween<double>(begin: 0.5, end: 1.0).chain(
                  CurveTween(curve: Curves.easeOutBack),
                ),
              ),
              child: Image.asset(
                'assets/logo.png', // Replace with your logo file path
                height: 700,
                width: 600,
              ),
            ),
            // SizedBox(height: 16),
            // FAProgressBar(
            //   currentValue: 100,
            //   displayText: '%',
            //   borderRadius: BorderRadius.circular(5),
            //   progressColor: Colors.greenAccent,
            //   backgroundColor: Colors.black38,
            // ),
            // SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
