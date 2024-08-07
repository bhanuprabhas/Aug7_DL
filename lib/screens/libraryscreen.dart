import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> recentReads = [];
  List<dynamic> topReads = [];
  Map<String, List<dynamic>> subjectBooksMap = {};
  bool isLoadingRecentReads = true;
  bool isLoadingTopReads = true;
  bool isLoadingBooks = true;
  Map<String, ScrollController> _subjectScrollControllers = {};
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredBooks = [];
  final GlobalKey _recentReadsKey = GlobalKey();
  final GlobalKey _topReadsKey = GlobalKey();
  final Map<String, GlobalKey> _subjectKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchRecentReads();
    _fetchTopReads();
    _fetchAllBooks();
    _searchController.addListener(_filterBooks);
  }

  Future<void> _fetchRecentReads() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username == null) {
      throw Exception('Username not found in local storage.');
    }

    final response = await http.get(
      Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/recentReads?username=$username'),
    );

    if (response.statusCode == 200) {
      setState(() {
        recentReads = json.decode(response.body);
        isLoadingRecentReads = false;
      });
    } else {
      throw Exception('Failed to load recent reads');
    }
  }

  Future<void> _fetchTopReads() async {
    try {
      final response = await http.get(
        Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/topReads'),
      );

      if (response.statusCode == 200) {
        setState(() {
          topReads = json.decode(response.body);
          isLoadingTopReads = false;
        });
      } else {
        throw Exception('Failed to load top reads');
      }
    } catch (e) {
      print('Error fetching top reads: $e');
      setState(() {
        isLoadingTopReads = false;
      });
    }
  }

  Future<void> _fetchAllBooks() async {
    try {
      final response = await http.get(
        Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/allBooks'),
      );

      if (response.statusCode == 200) {
        List<dynamic> fetchedBooks = json.decode(response.body);
        Map<String, List<dynamic>> subjectBooksMap = {};

        for (var book in fetchedBooks) {
          String subject = book['subject'];
          if (subjectBooksMap.containsKey(subject)) {
            subjectBooksMap[subject]!.add(book);
          } else {
            subjectBooksMap[subject] = [book];
            _subjectKeys[subject] = GlobalKey();
          }
        }

        subjectBooksMap.keys.forEach((subject) {
          _subjectScrollControllers[subject] = ScrollController();
        });

        setState(() {
          _filteredBooks = fetchedBooks;
          this.subjectBooksMap = subjectBooksMap;
          isLoadingBooks = false;
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e');
      setState(() {
        isLoadingBooks = false;
      });
    }
  }

  void _filterBooks() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBooks = subjectBooksMap.values.expand((books) => books).where((book) {
        return book['title'].toLowerCase().contains(query) ||
               book['author'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subjectScrollControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Library'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Scrollable.ensureVisible(
                    _recentReadsKey.currentContext!,
                    duration: Duration(milliseconds: 500),
                  );
                },
                child: Text('Recent Reads'),
              ),
              ElevatedButton(
                onPressed: () {
                  Scrollable.ensureVisible(
                    _topReadsKey.currentContext!,
                    duration: Duration(milliseconds: 500),
                  );
                },
                child: Text('Top Reads'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_subjectKeys.isNotEmpty) {
                    Scrollable.ensureVisible(
                      _subjectKeys.values.first.currentContext!,
                      duration: Duration(milliseconds: 500),
                    );
                  }
                },
                child: Text('Subjects'),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (isLoadingRecentReads)
                    CircularProgressIndicator()
                  else
                    _buildSection('Recent Reads', recentReads, _recentReadsKey),
                  if (isLoadingTopReads)
                    CircularProgressIndicator()
                  else
                    _buildSection('Top Reads', topReads, _topReadsKey),
                  if (isLoadingBooks)
                    CircularProgressIndicator()
                  else
                    ...subjectBooksMap.entries.map((entry) {
                      return _buildSubjectSection(entry.key, entry.value, _subjectKeys[entry.key]!);
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, GlobalKey key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  children: [
                    Image.network(items[index]['coverImageUrl'], height: 100),
                    Text(items[index]['title']),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSection(String subject, List<dynamic> books, GlobalKey key) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            subject,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          height: 150,
          child: ListView.builder(
            controller: _subjectScrollControllers[subject],
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  children: [
                    Image.network(books[index]['coverImageUrl'], height: 100),
                    Text(books[index]['title']),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
