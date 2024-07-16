import 'package:fllutter/screens/pdfViewerScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class BookDetailScreen extends StatelessWidget {
  final dynamic book;

  BookDetailScreen({required this.book});

  Future<void> openBook(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? username = prefs.getString('username'); // Get username from local storage

      if (username == null) {
        // Handle the case where username is not found in local storage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username not found. Please log in again.')),
        );
        return;
      }

      final String isbn = book['isbn'];

      final url = Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/signedbook')
          .replace(queryParameters: {'username': username, 'isbn': isbn});

      final response = await http.get(url);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String? pdfUrl = responseData['signedUrl']; // Adjust based on the actual response key

        if (pdfUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerPage( isbn: isbn),
            ),
          );
        } else {
          // Handle case where the signedBookUrl is null
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF. Please try again later.')),
          );
        }
      } else {
        // Handle error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF. Please try again later.')),
        );
      }
    } catch (e) {
      // Handle any exceptions that might occur
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book['title']),
      ),
      body: Padding(
        padding: EdgeInsets.all(32.0), // Increase padding for better spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 24, // Add extra space between app bar and content
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Display cover image if available
                if (book['coverPageURL'] != null)
                  Expanded(
                    flex: 1,
                    child: Image.network(
                      book['coverPageURL'],
                      height: 300, // Adjust height for TV view
                      fit: BoxFit.contain, // Ensure image fits well
                    ),
                  ),
                SizedBox(width: 24), // Add space between image and details
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        book['title'],
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Author: ' + (book['author'] as List<dynamic>).join(', '),
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Publisher: ${book['publisher']}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Subject: ${book['subject']}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ISBN: ${book['isbn']}',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => openBook(context),
                        child: Text('Read Book', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
