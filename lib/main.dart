import 'package:fllutter/screens/homeScreen.dart';
import 'package:fllutter/screens/login_Screen.dart';
import 'package:flutter/material.dart';
import 'package:fllutter/screens/pdfViewerScreen.dart'; // Import PDFViewerScreen directly

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Library @rcts',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.grey[200], // Adjust background color
      ),
      home: LoginScreen(), // Directly navigate to PDFViewerScreen
    );
  }
}
