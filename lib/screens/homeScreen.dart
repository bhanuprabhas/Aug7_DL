import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fllutter/screens/bookDetailScreen.dart';
import 'package:fllutter/widgets/colors.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> books = [];
  List<dynamic> filteredBooks = [];
  List<dynamic> topReads = [];
  bool isLoadingTopReads = true;
  int focusedBookIndex = 0;
  int focusedTopReadIndex = 0;
  int focusedSubjectIndex = 0;
  ScrollController _mainScrollController = ScrollController();
  ScrollController _topReadsController = ScrollController();
  Map<String, List<dynamic>> _subjectBooksMap = {};
  Map<String, ScrollController> _subjectScrollControllers = {};
  bool isTopReadsRowFocused = false;
  bool isSubjectRowFocused = false;
  String focusedSubject = '';

  Future<List<dynamic>>? _recentReadsFuture;
  List<dynamic> recentReads = [];
  int focusedRecentReadIndex = 0;
  bool isRecentReadsRowFocused = false;
  ScrollController _recentReadsController = ScrollController();
  bool isInitialLoad = true;

  bool _isActive = true;

  bool isSearchBarFocused = false;
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  FocusNode _homeScreenFocusNode =
      FocusNode(); // New focus node for the HomeScreen

  bool shouldKeepSearchBarFocused = false; // Flag to manage search bar focus

  // New variables for buttons section
  int focusedButtonsIndex = 0;
  bool isButtonsRowFocused = false;
  List<String> buttonLabels = ['Recent Reads', 'Top Reads'];
  ScrollController _buttonsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchTopReads();
    _recentReadsFuture = fetchRecentReads();
    _loadRecentReads();

    // Listen to focus changes
    _homeScreenFocusNode.addListener(() {
      _onFocusChange(_homeScreenFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _topReadsController.dispose();
    _recentReadsController.dispose();
    _mainScrollController.dispose();
    _buttonsScrollController
        .dispose(); // Dispose of the buttons scroll controller
    _searchController.dispose();
    _searchFocusNode.dispose();
    _homeScreenFocusNode.dispose(); // Dispose of the HomeScreen focus node
    super.dispose();
  }

  void _onFocusChange(bool isFocused) {
    setState(() {
      _isActive = isFocused;
      print(
          'HomeScreen isActive: $_isActive'); // Print statement to show HomeScreen active status
    });
  }

  void _loadRecentReads() async {
    try {
      recentReads = await _recentReadsFuture!;
      setState(() {
        isInitialLoad = false;
      });
    } catch (e) {
      print('Failed to load recent reads: $e');
      setState(() {
        isInitialLoad = false;
      });
    }
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(
          Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/allBooks'));
      if (response.statusCode == 200) {
        List<dynamic> fetchedBooks = json.decode(response.body);
        Map<String, List<dynamic>> subjectBooksMap = {};

        for (var book in fetchedBooks) {
          String subject = book['subject'];
          if (subjectBooksMap.containsKey(subject)) {
            subjectBooksMap[subject]!.add(book);
          } else {
            subjectBooksMap[subject] = [book];
          }
        }

        subjectBooksMap.keys.forEach((subject) {
          _subjectScrollControllers[subject] = ScrollController();
        });

        // Sort the subjects and add them to buttonLabels
        List<String> sortedSubjects = subjectBooksMap.keys.toList();
        setState(() {
          books = fetchedBooks;
          _subjectBooksMap = subjectBooksMap;
          buttonLabels.addAll(sortedSubjects);
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e');
    }
  }

  Future<void> fetchTopReads() async {
    try {
      final response = await http.get(
          Uri.parse('https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/topReads'));
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

  Future<List<dynamic>> fetchRecentReads() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username == null) {
      throw Exception('Username not found in local storage.');
    }

    final response = await http.get(
      Uri.parse(
          'https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/recentReads?username=$username'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load recent reads');
    }
  }

  void scrollLeft() {
    setState(() {
      if (isSearchBarFocused) {
        return;
      } else if (isButtonsRowFocused) {
        if (focusedButtonsIndex > 0) {
          focusedButtonsIndex--;
          _scrollToButton(focusedButtonsIndex);
        }
      } else if (isRecentReadsRowFocused) {
        if (focusedRecentReadIndex > 0) {
          focusedRecentReadIndex--;
          _scrollToRecentRead(focusedRecentReadIndex);
        }
      } else if (isTopReadsRowFocused) {
        if (focusedTopReadIndex > 0) {
          focusedTopReadIndex--;
          _scrollToTopRead(focusedTopReadIndex);
        }
      } else if (isSubjectRowFocused) {
        if (focusedBookIndex > 0 &&
            _subjectBooksMap.containsKey(focusedSubject)) {
          focusedBookIndex--;
          _scrollToSubjectBook(focusedSubject, focusedBookIndex);
        }
      }
    });
  }

  void scrollRight() {
    setState(() {
      if (isSearchBarFocused) {
        return;
      } else if (isButtonsRowFocused) {
        if (focusedButtonsIndex < buttonLabels.length - 1) {
          focusedButtonsIndex++;
          _scrollToButton(focusedButtonsIndex);
        }
      } else if (isRecentReadsRowFocused) {
        if (focusedRecentReadIndex < recentReads.length - 1) {
          focusedRecentReadIndex++;
          _scrollToRecentRead(focusedRecentReadIndex);
        }
      } else if (isTopReadsRowFocused) {
        if (focusedTopReadIndex < topReads.length - 1) {
          focusedTopReadIndex++;
          _scrollToTopRead(focusedTopReadIndex);
        }
      } else if (isSubjectRowFocused) {
        if (focusedBookIndex < _subjectBooksMap[focusedSubject]!.length - 1) {
          focusedBookIndex++;
          _scrollToSubjectBook(focusedSubject, focusedBookIndex);
        }
      }
    });
  }

  void _scrollToButton(int index) {
    _buttonsScrollController.animateTo(
      index * 100.0, // Adjust this value as needed based on your button width
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToRecentRead(int index) {
    _recentReadsController.animateTo(
      index * 150.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToTopRead(int index) {
    _topReadsController.animateTo(
      index * 150.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSubjectBook(String subject, int index) {
    _subjectScrollControllers[subject]?.animateTo(
      index * 150.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToFocusedSection(double offset) {
    if (_mainScrollController.hasClients) {
      _mainScrollController.animateTo(
        offset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void handleKeyEvent(RawKeyEvent event) {
    print(
        'HomeScreen handleKeyEvent: ${_homeScreenFocusNode.hasFocus}'); // Print focus state during key event handling
    if (_homeScreenFocusNode.hasFocus &&
        event.runtimeType.toString() == 'RawKeyDownEvent') {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Left':
          scrollLeft();
          break;
        case 'Arrow Right':
          scrollRight();
          break;
        case 'Arrow Up':
          handleArrowUp();
          break;
        case 'Arrow Down':
          handleArrowDown();
          break;
        case 'Enter':
        case 'Select':
          handleSelect();
          break;
        default:
          print('Unhandled key: ${event.logicalKey.debugName}');
          break;
      }
    }
  }

  void handleArrowUp() {
    setState(() {
      if (isSearchBarFocused) {
        isSearchBarFocused = false;
        shouldKeepSearchBarFocused =
            false; // Disable keeping the search bar focused
        _scrollToFocusedSection(0);
      } else if (isButtonsRowFocused) {
        isButtonsRowFocused = false;
        isSearchBarFocused = true;
        _scrollToFocusedSection(0);
      } else if (isSubjectRowFocused) {
        if (focusedSubjectIndex > 0) {
          focusedSubjectIndex--;
          focusedSubject = _subjectBooksMap.keys.toList()[focusedSubjectIndex];
          focusedBookIndex = 0;
          _scrollToFocusedSection((focusedSubjectIndex + 1) * 260.0);
        } else {
          isSubjectRowFocused = false;
          isTopReadsRowFocused = true;
          _scrollToFocusedSection(250.0);
        }
      } else if (isTopReadsRowFocused) {
        isTopReadsRowFocused = false;
        isRecentReadsRowFocused = true;
        _scrollToFocusedSection(80.0);
      } else if (isRecentReadsRowFocused) {
        isRecentReadsRowFocused = false;
        isButtonsRowFocused = true;
        _scrollToFocusedSection(40.0);
      }
    });
  }

  void handleArrowDown() {
    setState(() {
      if (isSearchBarFocused) {
        isSearchBarFocused = false;
        shouldKeepSearchBarFocused = true; // Keep the search bar focused
        isButtonsRowFocused = true;
        _scrollToFocusedSection(40.0);
      } else if (isButtonsRowFocused) {
        isButtonsRowFocused = false;
        isRecentReadsRowFocused = true;
        _scrollToFocusedSection(100.0);
      } else if (isRecentReadsRowFocused) {
        isRecentReadsRowFocused = false;
        isTopReadsRowFocused = true;
        _scrollToFocusedSection(200.0);
      } else if (isTopReadsRowFocused) {
        isTopReadsRowFocused = false;
        isSubjectRowFocused = true;
        focusedSubject = _subjectBooksMap.keys.toList()[focusedSubjectIndex];
        _scrollToFocusedSection(400.0);
      } else if (isSubjectRowFocused) {
        if (focusedSubjectIndex < _subjectBooksMap.keys.length - 1) {
          focusedSubjectIndex++;
          focusedSubject = _subjectBooksMap.keys.toList()[focusedSubjectIndex];
          _scrollToFocusedSection((focusedSubjectIndex + 1) * 250.0);
        }
      } else {
        isSearchBarFocused = true;
        _scrollToFocusedSection(0);
      }
    });
  }

  void handleSelect() {
    if (isSearchBarFocused) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    } else if (isButtonsRowFocused) {
      setState(() {
        isButtonsRowFocused = false;
        switch (focusedButtonsIndex) {
          case 0: // Recent Reads
            isRecentReadsRowFocused = true;
            _scrollToFocusedSection(80.0);
            break;
          case 1: // Top Reads
            isTopReadsRowFocused = true;
            _scrollToFocusedSection(250.0);
            break;
          default: // Subjects
            focusedSubjectIndex = focusedButtonsIndex - 2;
            isSubjectRowFocused = true;
            focusedSubject = buttonLabels[focusedButtonsIndex];
            _scrollToFocusedSection((focusedSubjectIndex + 1) * 250.0);
            break;
        }
      });
    } else if (isTopReadsRowFocused && focusedTopReadIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsScreen(
            book: topReads[focusedTopReadIndex],
            onBookRead: _loadRecentReads,
          ),
        ),
      ).then((_) {
        FocusScope.of(context)
            .requestFocus(_homeScreenFocusNode); // Refocus on HomeScreen
      });
    } else if (isRecentReadsRowFocused && focusedRecentReadIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsScreen(
            book: recentReads[focusedRecentReadIndex],
            onBookRead: _loadRecentReads,
          ),
        ),
      ).then((_) {
        FocusScope.of(context)
            .requestFocus(_homeScreenFocusNode); // Refocus on HomeScreen
      });
    } else if (isSubjectRowFocused && focusedBookIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailsScreen(
            book: _subjectBooksMap[focusedSubject]![focusedBookIndex],
            onBookRead: _loadRecentReads,
          ),
        ),
      ).then((_) {
        FocusScope.of(context)
            .requestFocus(_homeScreenFocusNode); // Refocus on HomeScreen
      });
    }
  }

  void filterBooks(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredBooks = [];
      });
      return;
    }

    List<dynamic> filtered = books
        .where((book) => book['title']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    setState(() {
      filteredBooks = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: const Text(
          'Digital Library @RCTS',
          style: TextStyle(color: AppColors.textColor),
        ),
      ),
      body: RawKeyboardListener(
        focusNode: _homeScreenFocusNode,
        onKey: handleKeyEvent,
        autofocus: true,
        child: SingleChildScrollView(
          controller: _mainScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isSearchBarFocused
                      ? Colors.grey[800]
                      : Colors.transparent,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search books...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: TextStyle(color: Colors.black),
                  enabled: isSearchBarFocused,
                  onChanged: (value) {
                    filterBooks(value);
                  },
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              SizedBox(height: 20),
              // Buttons Section
              Container(
                height: 50.0,
                color: Colors.grey[900],
                child: ListView.builder(
                  controller: _buttonsScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: buttonLabels.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          focusedButtonsIndex = index;
                          handleSelect();
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: focusedButtonsIndex == index
                                ? Colors.red
                                : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                        child: Text(
                          buttonLabels[index],
                          style: TextStyle(
                            color: focusedButtonsIndex == index
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (filteredBooks.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Search Results',
                        style: TextStyle(
                          color: AppColors.textColor,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      height: 150.0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailsScreen(
                                    book: filteredBooks[index],
                                    onBookRead: _loadRecentReads,
                                  ),
                                ),
                              );
                            },
                            child: _buildBookCard(
                              filteredBooks[index],
                              index == focusedBookIndex && isSubjectRowFocused,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else if (_searchController.text.isEmpty)
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isRecentReadsRowFocused
                            ? Colors.grey[800]
                            : Colors.transparent,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Recent Reads',
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            height: 150.0,
                            child: isInitialLoad
                                ? Center(child: CircularProgressIndicator())
                                : recentReads.isEmpty
                                    ? Center(
                                        child:
                                            Text('No recent reads available'))
                                    : ListView.builder(
                                        controller: _recentReadsController,
                                        scrollDirection: Axis.horizontal,
                                        itemCount: recentReads.length,
                                        itemBuilder: (context, index) {
                                          final recentbook = recentReads[index];
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BookDetailsScreen(
                                                    book: recentbook,
                                                    onBookRead:
                                                        _loadRecentReads,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: buildRecentReadsCard(
                                              recentbook,
                                              index == focusedRecentReadIndex &&
                                                  isRecentReadsRowFocused,
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: isTopReadsRowFocused
                            ? Colors.grey[800]
                            : Colors.transparent,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Top Reads',
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          isLoadingTopReads
                              ? Center(child: CircularProgressIndicator())
                              : Container(
                                  height: 150.0,
                                  child: ListView.builder(
                                    controller: _topReadsController,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: topReads.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BookDetailsScreen(
                                                book: topReads[index],
                                                onBookRead: _loadRecentReads,
                                              ),
                                            ),
                                          );
                                        },
                                        child: _buildTopReadsCard(
                                          topReads[index],
                                          index == focusedTopReadIndex &&
                                              isTopReadsRowFocused,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_subjectBooksMap.isEmpty)
                      const Center(
                          child: Text('No books available',
                              style: TextStyle(color: AppColors.textColor)))
                    else
                      ..._subjectBooksMap.entries.map((entry) {
                        String subject = entry.key;
                        List<dynamic> booksList = entry.value;
                        bool isFocusedSubject =
                            _subjectBooksMap.keys.toList().indexOf(subject) ==
                                focusedSubjectIndex;
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          color: isFocusedSubject && isSubjectRowFocused
                              ? Colors.grey[800]
                              : Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  subject,
                                  style: TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                height: 150.0,
                                child: ListView.builder(
                                  controller:
                                      _subjectScrollControllers[subject],
                                  scrollDirection: Axis.horizontal,
                                  itemCount: booksList.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                BookDetailsScreen(
                                              book: booksList[index],
                                              onBookRead: _loadRecentReads,
                                            ),
                                          ),
                                        );
                                      },
                                      child: _buildBookCard(
                                        booksList[index],
                                        index == focusedBookIndex &&
                                            isFocusedSubject &&
                                            isSubjectRowFocused,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, bool isFocused) {
    double scaleFactor =
        isFocused ? 1.0 : 0.95; // Scale factor for focused item
    Color borderColor = isFocused
        ? Colors.red
        : Colors.transparent; // Border color based on focus

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SizedBox(
        width: 140.0, // Width of each book card
        height: 140.0, // Height of each book card
        child: GestureDetector(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300), // Animation duration
            transform: Matrix4.identity()..scale(scaleFactor), // Apply scaling
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 4.0),
              borderRadius:
                  BorderRadius.circular(8.0), // Adjusted for better appearance
              color: Colors.white,
              boxShadow: [
                if (isFocused)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    book['coverPageURL'] ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    book['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 12.0, // Increased for better readability
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopReadsCard(Map<String, dynamic> topRead, bool isFocused) {
    double scaleFactor =
        isFocused ? 1.0 : 0.95; // Scale factor for focused item
    Color borderColor = isFocused
        ? Colors.red
        : Colors.transparent; // Border color based on focus

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SizedBox(
        width: 140.0, // Width of each top reads card
        height: 140.0, // Height of each top reads card
        child: GestureDetector(
          onTap: () {
            // Handle tap on top reads item
            print('Tapped on ${topRead['title']}');
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300), // Animation duration
            transform: Matrix4.identity()..scale(scaleFactor), // Apply scaling
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 4.0),
              borderRadius: BorderRadius.circular(2.0),
              color: Colors.white,
              boxShadow: [
                if (isFocused)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    topRead['coverPageURL'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    topRead['title'],
                    style: TextStyle(
                      fontSize: 10.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRecentReadsCard(dynamic recentbook, bool isFocused) {
    double scaleFactor =
        isFocused ? 1.0 : 0.95; // Scale factor for focused item
    Color borderColor = isFocused
        ? Colors.red
        : Colors.transparent; // Border color based on focus

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: SizedBox(
        width: 140.0, // Width of each top reads card
        height: 140.0, // Height of each top reads card
        child: GestureDetector(
          // onTap: () {
          //   // Handle tap on top reads item
          //   print('Tapped on ${recent['title']}');
          // },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300), // Animation duration
            transform: Matrix4.identity()..scale(scaleFactor), // Apply scaling
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 4.0),
              borderRadius: BorderRadius.circular(2.0),
              color: Colors.white,
              boxShadow: [
                if (isFocused)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    recentbook['coverPageURL'] ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    recentbook['title'] ?? 'Unknown Title',
                    style: const TextStyle(
                      fontSize: 12.0, // Increased for better readability
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
