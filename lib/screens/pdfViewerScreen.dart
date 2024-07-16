import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PdfViewerPage extends StatefulWidget {
  final String isbn;

  PdfViewerPage({required this.isbn});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localFilePath;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;

  PdfViewerController pdfViewerController = PdfViewerController();
  bool _isPdfViewerFocused = false;

  // FocusNode for managing focus on AppBar
  late FocusNode _appBarFocusNode;

  @override
  void initState() {
    super.initState();
    _initializePdfViewer();
    _appBarFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _appBarFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializePdfViewer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    if (username != null) {
      String presignedUrl = await _getPresignedUrl(username, widget.isbn);
      if (presignedUrl.isNotEmpty) {
        await downloadFile(presignedUrl);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getPresignedUrl(String username, String isbn) async {
    final url = 'https://pl-api.iiit.ac.in/rcts/ETL-PE-003/info/signedBook';
    final response = await http.get(
      Uri.parse('$url?username=$username&isbn=$isbn'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['signedUrl'] ?? '';
    } else {
      print('Failed to get presigned URL: ${response.statusCode}');
      return '';
    }
  }

  Future<void> downloadFile(String presignedUrl) async {
    try {
      final response = await http.get(Uri.parse(presignedUrl));
      if (response.statusCode == 200) {
        final Directory dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/downloaded_pdf.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          localFilePath = file.path;
          _isLoading = false;
        });
      } else {
        print('Failed to download file: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error downloading file: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPageJumpDialog(BuildContext context) {
    int currentPage = _currentPage;
    int totalPages = _totalPages;

    TextEditingController pageController =
        TextEditingController(text: (currentPage + 1).toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Jump to Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: pageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Page Number'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                int pageNumber = int.tryParse(pageController.text) ?? 1;
                if (pageNumber >= 1 && pageNumber <= totalPages) {
                  setState(() {
                    _currentPage = pageNumber - 1;
                  });
                  pdfViewerController.jumpToPage(pageNumber - 1);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid page number!'),
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(String searchTerm) {
    if (searchTerm.isNotEmpty) {
      // Implement your search logic here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: $searchTerm'),
        ),
      );
    }
  }

  void _zoomIn() {
    // Increase the zoom level
    pdfViewerController.zoomLevel = pdfViewerController.zoomLevel + 0.5;
  }

  void _zoomOut() {
    // Decrease the zoom level
    pdfViewerController.zoomLevel = pdfViewerController.zoomLevel - 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text(
          'PDF Viewer',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: Icon(FontAwesomeIcons.solidFilePdf),
            color: _isPdfViewerFocused ? Colors.red : Colors.black,
            onPressed: () {
              _showPageJumpDialog(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            color: _isPdfViewerFocused ? Colors.red : Colors.black,
            onPressed: () {
              _performSearch('');
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _isPdfViewerFocused = true;
                    FocusScope.of(context).requestFocus(_appBarFocusNode);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isPdfViewerFocused ? Colors.red : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isPdfViewerFocused ? Colors.red.withOpacity(0.5) : Colors.transparent,
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SfPdfViewer.file(
                    File(localFilePath!),
                    controller: pdfViewerController,
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      setState(() {
                        _totalPages = details.document.pages.count;
                      });
                    },
                    onDocumentLoadFailed:
                        (PdfDocumentLoadFailedDetails details) {
                      print('Document load failed: ${details.error}');
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showPageJumpDialog(context);
        },
        tooltip: 'Jump to Page',
        child: Icon(Icons.forward),
      ),
    );
  }
}