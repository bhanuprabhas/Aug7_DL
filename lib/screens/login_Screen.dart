import 'package:flutter/material.dart';
import 'package:fllutter/widgets/login.dart'; // Assuming login.dart contains LoginForm

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20.0),
          width: 400.0, // Adjust width based on TV screen size
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Image.asset('assets/images/logo.png'),
              Text(
                'Login',
                style: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.0),
              LoginForm(), // Use the LoginForm widget here
            ],
          ),
        ),
      ),
    );
  }
}
