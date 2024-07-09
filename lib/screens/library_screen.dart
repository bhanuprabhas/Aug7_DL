import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/searchBar.dart'; // Adjusted import path
import 'bookDetailScreen.dart'; // Import your BookDetailScreen file here

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> books = [];
  List<dynamic> topReads = [];
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchTopReads();
  }

  // Fetch the data of books from API
  fetchBooks() async {
    final response = await http.get(
        Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/allBooks'));
    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          books = jsonResponse;
          isLoading = false;
        });
      } catch (e) {
        print('Error parsing JSON: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to load books');
    }
  }

  // Fetch the data of top reads from API
  fetchTopReads() async {
    final response = await http.get(
        Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/topReads'));
    if (response.statusCode == 200) {
      try {
        final List<dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          topReads = jsonResponse;
          isLoading = false;
        });
      } catch (e) {
        print('Error parsing JSON: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to load top reads');
    }
  }

  void updateSearchBarFocus(bool isFocused) {
    setState(() {
      if (!isFocused) {
        isSearching = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Digital Library @rcts', style: TextStyle(color: Colors.red)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Focus(
              onFocusChange: (isFocused) {
                updateSearchBarFocus(isFocused);
              },
              child: Search_Bar(
                onSearchResults: (results) {
                  setState(() {
                    searchResults = results;
                    isSearching = true;
                  });
                },
                books: books,
                onFocusChange: updateSearchBarFocus,
              ),
            ),
            if (!isSearching)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Popular Reads',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200, // Adjust height as needed
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: topReads.length,
                        itemBuilder: (context, index) {
                          final book = topReads[index];
                          return buildTopReadCard(book); // Use common method
                        },
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Books from library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context)
                  .size
                  .height, // Set a fixed height for the GridView
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // Disable GridView scrolling
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // Number of cards per row
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 20.0,
                          childAspectRatio:
                              0.7, // Adjust aspect ratio as needed
                        ),
                        itemCount:
                            isSearching ? searchResults.length : books.length,
                        itemBuilder: (context, index) {
                          final book =
                              isSearching ? searchResults[index] : books[index];
                          return buildBookCard(book); // Use common method
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

//card inside styles for the allbooks and the topreads

  Widget buildBookCard(dynamic book) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0), // Adjust the border radius here
      ),
      margin: EdgeInsets.all(8),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
        child: Container(
          width: 120, // Adjust width as needed
          height: 250, // Adjust height to match the top read cards
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    image: book['coverPageURL'] != null
                        ? DecorationImage(
                            image: NetworkImage(book['coverPageURL']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: book['coverPageURL'] == null
                      ? Icon(Icons.book, size: 72, color: Colors.grey)
                      : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book['title'] ?? 'No Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTopReadCard(dynamic book) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0), // Adjust the border radius here
      ),
      margin: EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
        child: Container(
          width: 120, // Adjust width as needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    image: book['coverPageURL'] != null
                        ? DecorationImage(
                            image: NetworkImage(book['coverPageURL']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: book['coverPageURL'] == null
                      ? Icon(Icons.book, size: 72, color: Colors.grey)
                      : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      book['title'] ?? 'No Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
