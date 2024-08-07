import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/colors.dart';




class PdfViewerPage extends StatefulWidget {
  final String isbn;
  final int initialPage;

  PdfViewerPage({required this.isbn, this.initialPage = 0});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _presignedUrl;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;

  PdfViewerController pdfViewerController = PdfViewerController();
  bool _isPdfViewerFocused = true;

  late FocusNode _zoomInFocusNode;
  late FocusNode _zoomOutFocusNode;
  late FocusNode _pageJumpFocusNode;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _zoomInFocusNode = FocusNode();
    _zoomOutFocusNode = FocusNode();
    _pageJumpFocusNode = FocusNode();
    _searchFocusNode = FocusNode();
    _initializePdfViewer();
  }

  @override
  void dispose() {
    _zoomInFocusNode.dispose();
    _zoomOutFocusNode.dispose();
    _pageJumpFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializePdfViewer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('username') ?? 'hariuser';
    String presignedUrl = await _getPresignedUrl(username, widget.isbn);
    if (presignedUrl.isNotEmpty) {
      setState(() {
        _presignedUrl = presignedUrl;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pdfViewerController != null) {
          pdfViewerController.jumpToPage(widget.initialPage);
        }
      });
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
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setInt('${widget.isbn}_last_viewed_page', pageNumber - 1);
                  });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for: $searchTerm'),
        ),
      );
    }
  }

  void _zoomIn() {
    final currentZoom = pdfViewerController.zoomLevel;
    pdfViewerController.zoomLevel = (currentZoom + 0.5).clamp(1.0, 5.0);
  }

  void _zoomOut() {
    final currentZoom = pdfViewerController.zoomLevel;
    pdfViewerController.zoomLevel = (currentZoom - 0.5).clamp(1.0, 5.0);
  }

  Future<bool> _onWillPop() async {
    if (_isPdfViewerFocused) {
      FocusScope.of(context).requestFocus(_zoomInFocusNode);
      _isPdfViewerFocused = false;
      setState(() {});
      return false;
    } else if (_zoomInFocusNode.hasFocus ||
        _zoomOutFocusNode.hasFocus ||
        _pageJumpFocusNode.hasFocus ||
        _searchFocusNode.hasFocus) {
      bool exitApp = await _showExitDialog();
      if (exitApp) {
        return true;
      } else {
        FocusScope.of(context).requestFocus(_zoomInFocusNode);
        setState(() {});
        return false;
      }
    } else {
      FocusScope.of(context).requestFocus(_zoomInFocusNode);
      _isPdfViewerFocused = false;
      setState(() {});
      return false;
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit PDF Viewer'),
            content: Text('Are you sure you want to exit the PDF viewer?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          leading: Icon(Icons.arrow_back, color: Colors.white),
          title: Text('PDF Viewer', style: TextStyle(color: AppColors.textColor)),
          actions: [
            Focus(
              focusNode: _zoomInFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return IconButton(
                    icon: Icon(Icons.zoom_in, color: isFocused ? Colors.blue : Colors.white),
                    onPressed: _zoomIn,
                  );
                },
              ),
            ),
            Focus(
              focusNode: _zoomOutFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return IconButton(
                    icon: Icon(Icons.zoom_out, color: isFocused ? Colors.blue : Colors.white),
                    onPressed: _zoomOut,
                  );
                },
              ),
            ),
            Focus(
              focusNode: _pageJumpFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return IconButton(
                    icon: Icon(Icons.arrow_forward, color: isFocused ? Colors.blue : Colors.white),
                    onPressed: () => _showPageJumpDialog(context),
                  );
                },
              ),
            ),
            Focus(
              focusNode: _searchFocusNode,
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return IconButton(
                    icon: Icon(Icons.search, color: isFocused ? Colors.blue : Colors.white),
                    onPressed: () => _performSearch('search term'),
                  );
                },
              ),
            ),
          ],
        ),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : SfPdfViewer.network(
                  _presignedUrl!,
                  controller: pdfViewerController,
                  onPageChanged: (PdfPageChangedDetails details) {
                    _updateLastViewedPage(details.newPageNumber);
                  },
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (pdfViewerController != null) {
                        pdfViewerController.jumpToPage(widget.initialPage);
                      }
                    });
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    print('Document load failed: ${details.error}');
                  },
                ),
        ),
      ),
    );
  }

  void _updateLastViewedPage(int pageNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('${widget.isbn}_last_viewed_page', pageNumber);
    setState(() {
      _currentPage = pageNumber - 1;
    });
  }
}