import 'package:fllutter/screens/pdfViewerScreen.dart';
import 'package:flutter/material.dart';


class BookDetailScreen extends StatelessWidget {
  final dynamic book;

  BookDetailScreen({required this.book});

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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PDFViewerScreen(assetPath: 'assets/a.pdf'),
                            ),
                          );
                        },
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
