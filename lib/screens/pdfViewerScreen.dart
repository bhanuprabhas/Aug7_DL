import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatelessWidget {
  final String assetPath;

  PDFViewerScreen({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue,
        title: Text('PDF Viewer'),
      ),
      body: SfPdfViewer.asset(
        assetPath,
        canShowPaginationDialog: true, // Optional feature to show pagination dialog
      ),
    );
  }
}
