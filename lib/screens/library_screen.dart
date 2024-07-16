import 'package:fllutter/widgets/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/searchBar.dart';
import 'bookDetailScreen.dart';

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
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Digital Library @rcts',
            style: TextStyle(color: AppColors.textColor)),
        centerTitle: false,
        backgroundColor: AppColors.backgroundColor,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Popular Reads',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: topReads.length,
                        itemBuilder: (context, index) {
                          final book = topReads[index];
                          return buildTopReadCard(book);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Books from library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
            // Display general list of books
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 20.0,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: isSearching ? searchResults.length : books.length,
                  itemBuilder: (context, index) {
                    final book =
                        isSearching ? searchResults[index] : books[index];
                    return buildBookCard(book);
                  },
                ),
              ),
            // Display books grouped by subjects
            if (!isLoading) ...buildSubjectBlocks(),
          ],
        ),
      ),
    );
  }

  // Method to build subject blocks dynamically
  List<Widget> buildSubjectBlocks() {
    // Extract all unique subjects from books list
    Set<String> uniqueSubjects = Set<String>();
    books.forEach((book) {
      uniqueSubjects.add(book['subject']);
    });

    // Create a list of widgets for each subject
    List<Widget> subjectBlocks = [];
    uniqueSubjects.forEach((subject) {
      subjectBlocks.add(buildSubjectBlock(subject));
    });

    return subjectBlocks;
  }

  // Method to build a subject block for a specific subject
  Widget buildSubjectBlock(String subject) {
    // Filter books by the specified subject
    List<dynamic> booksBySubject =
        books.where((book) => book['subject'] == subject).toList();

    // Return a column with the subject title and a horizontal list view of books
    return booksBySubject.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    subject,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: booksBySubject.length,
                    itemBuilder: (context, index) {
                      final book = booksBySubject[index];
                      return buildBookCard(book);
                    },
                  ),
                ),
              ],
            ),
          )
        : SizedBox(); // Return empty SizedBox if no books found for the subject
  }

  Widget buildBookCard(dynamic book) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
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
          width: 120,
          height: 250,
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
        borderRadius: BorderRadius.circular(0),
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
          width: 120,
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
