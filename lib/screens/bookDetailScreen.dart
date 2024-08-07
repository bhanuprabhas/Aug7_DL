import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import '../widgets/colors.dart';
import '../screens/pdfViewerScreen.dart'; // This widget is used to retrieve and view the PDF
// import '../constantsHelpers/book.dart'; // This class is used to store book details

class BookDetailsScreen extends StatefulWidget {
  // final Book book;
  final Map<String, dynamic> book; // Accept book as a map


  const BookDetailsScreen({Key? key, required this.book,required void Function() onBookRead})
      : super(key: key);

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late FocusNode _readButtonFocusNode;
  late FocusNode _continueReadingButtonFocusNode;

  @override
  void initState() {
    super.initState();
    _readButtonFocusNode = FocusNode();
    _continueReadingButtonFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readButtonFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _readButtonFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _readButtonFocusNode.dispose();
    _continueReadingButtonFocusNode.dispose();
    super.dispose();
  }

  void openPdfViewer(BuildContext context, {int initialPage = 0}) async {
    String isbnNumber = widget.book['isbn'];
    if (isbnNumber.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            isbn: isbnNumber,
            initialPage: initialPage,
          ),
        ),
      ).then((_) {
        _readButtonFocusNode.requestFocus();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid Pdf'),
        ),
      );
    }
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_readButtonFocusNode.hasFocus) {
          _continueReadingButtonFocusNode.requestFocus();
        } else if (_continueReadingButtonFocusNode.hasFocus) {
          _readButtonFocusNode.requestFocus();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_continueReadingButtonFocusNode.hasFocus) {
          _readButtonFocusNode.requestFocus();
        } else if (_readButtonFocusNode.hasFocus) {
          _continueReadingButtonFocusNode.requestFocus();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.select) {
        if (_readButtonFocusNode.hasFocus) {
          openPdfViewer(context);
        } else if (_continueReadingButtonFocusNode.hasFocus) {
          _continueReading();
        }
      }
    }
  }

  void _continueReading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastViewedPage = prefs.getInt('${widget.book['isbn']}_last_viewed_page') ?? 0;
    openPdfViewer(context, initialPage: lastViewedPage);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyPress,
      autofocus: true,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            widget.book['title'] ?? 'No Title',
            style: TextStyle(color: Color.fromARGB(255, 122, 164, 212)),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Card(
            color: AppColors.backgroundColor,
            elevation: 8.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    height: double.infinity,
                    child: Image.network(
                      widget.book['coverPageURL'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                           widget.book['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Authors: ${widget.book['author']?.join(', ') ?? 'Unknown'}',
                          style: TextStyle(
                              fontSize: 18.0, color: AppColors.textColor),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Publisher: ${widget.book['publisher'] ?? 'Unknown'}',
                          style: TextStyle(
                              fontSize: 18.0, color: AppColors.textColor),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Subject: ${widget.book['subject'] ?? 'Unknown'}',
                          style: TextStyle(
                              fontSize: 18.0, color: AppColors.textColor),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'ISBN: ${widget.book['isbn'] ?? 'Unknown'}',
                          style: TextStyle(
                              fontSize: 18.0, color: AppColors.textColor),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Reads: ${widget.book['reads'] ?? 'Unknown'}',
                          style: TextStyle(
                              fontSize: 18.0, color: AppColors.textColor),
                        ),
                        SizedBox(height: 16.0),
                        FocusTraversalGroup(
                          policy: WidgetOrderTraversalPolicy(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Focus(
                                focusNode: _readButtonFocusNode,
                                onFocusChange: (hasFocus) {
                                  setState(() {});
                                },
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.testColor,
                                    side: BorderSide(
                                      color: _readButtonFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 255, 255, 255)
                                          : Colors.transparent,
                                      width: _readButtonFocusNode.hasFocus
                                          ? 4.0
                                          : 0.0,
                                    ),
                                    elevation: _readButtonFocusNode.hasFocus
                                        ? 12.0
                                        : 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    shadowColor: _readButtonFocusNode.hasFocus
                                        ? Colors.red
                                        : Colors.transparent,
                                  ),
                                  onPressed: () {
                                    openPdfViewer(context);
                                  },
                                  child: Text(
                                    'Read',
                                    style: TextStyle(
                                      color: _readButtonFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 255, 255, 255)
                                          : const Color.fromARGB(
                                              255, 255, 255, 255),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Focus(
                                focusNode: _continueReadingButtonFocusNode,
                                onFocusChange: (hasFocus) {
                                  setState(() {});
                                },
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.testColor,
                                    side: BorderSide(
                                      color: _continueReadingButtonFocusNode
                                              .hasFocus
                                          ? const Color.fromARGB(
                                              255, 255, 255, 255)
                                          : Colors.transparent,
                                      width: _continueReadingButtonFocusNode
                                              .hasFocus
                                          ? 4.0
                                          : 0.0,
                                    ),
                                    elevation:
                                        _continueReadingButtonFocusNode.hasFocus
                                            ? 12.0
                                            : 4.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    shadowColor:
                                        _continueReadingButtonFocusNode.hasFocus
                                            ? Colors.red
                                            : Colors.transparent,
                                  ),
                                  onPressed: () async {
                                    _continueReading();
                                  },
                                  child: Text(
                                    'Continue Reading',
                                    style: TextStyle(
                                      color: _continueReadingButtonFocusNode
                                              .hasFocus
                                          ? const Color.fromARGB(
                                              255, 255, 255, 255)
                                          : const Color.fromARGB(
                                              255, 255, 255, 255),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
