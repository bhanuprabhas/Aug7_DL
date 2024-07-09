import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fllutter/screens/library_screen.dart';

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _loginButtonFocus = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _submitForm(BuildContext context) async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    final url = Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final role = responseData['role'];
        final username = responseData['username'];

        // Save role and username in local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', role);
        await prefs.setString('username', username);

        // Optionally, save the token if needed
        await prefs.setString('token', token);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );

        // Navigate to LibraryScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LibraryScreen()),
        );
      } else {
        // Handle error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.reasonPhrase}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
        ),
        SizedBox(height: 20.0),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_loginButtonFocus);
          },
        ),
        SizedBox(height: 20.0),
        ElevatedButton(
          focusNode: _loginButtonFocus,
          onPressed: () {
            _submitForm(context);
          },
          child: Text('Login'),
        ),
      ],
    );
  }
}
