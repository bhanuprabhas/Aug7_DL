import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        NavBarItem(title: 'Books'),
       
        // Add more navigation items as needed
      ],
    );
  }
}

class NavBarItem extends StatelessWidget {
  final String title;

  NavBarItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Implement navigation logic here
      },
      child: Text(
        title,
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
