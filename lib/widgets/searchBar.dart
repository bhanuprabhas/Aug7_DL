import 'package:fllutter/widgets/colors.dart';
import 'package:flutter/material.dart';

class Search_Bar extends StatefulWidget {
  final Function(List<dynamic>) onSearchResults;
  final List<dynamic> books;
  final ValueChanged<bool> onFocusChange; // Callback to notify focus changes

  Search_Bar({
    required this.onSearchResults,
    required this.books,
    required this.onFocusChange,
  });

  @override
  _Search_BarState createState() => _Search_BarState();
}

class _Search_BarState extends State<Search_Bar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'inTitle';
  bool _isDropdownFocused = false;

  void _searchBooks(String keyword) {
    List<dynamic> searchResults = widget.books.where((book) {
      String fieldToSearch = '';
      switch (_searchType) {
        case 'inTitle':
          fieldToSearch = book['title'];
          break;
        case 'inAuthor':
          fieldToSearch = (book['author'] as List<dynamic>).join(', ');
          break;
        case 'inPublisher':
          fieldToSearch = book['publisher'];
          break;
        case 'inISBN':
          fieldToSearch = book['isbn'];
          break;
        case 'inSubject':
          fieldToSearch = book['subject'];
          break;
        default:
          fieldToSearch = book['title'];
      }
      return fieldToSearch.toLowerCase().contains(keyword.toLowerCase());
    }).toList();

    widget.onSearchResults(searchResults);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              controller: _searchController,
              style: TextStyle(color: AppColors.textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIconColor: AppColors.iconColor,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                _searchBooks(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: DropdownButton<String>(
              value: _searchType,
              onChanged: (String? newValue) {
                setState(() {
                  _searchType = newValue!;
                });
                _searchBooks(_searchController.text);
              },
              items: <String>[
                'inTitle',
                'inAuthor',
                'inPublisher',
                'inISBN',
                'inSubject'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              // FocusNode and onTap for managing focus
              focusNode: FocusNode(),
              onTap: () {
                widget.onFocusChange(true); // Notify parent of focus change
                setState(() {
                  _isDropdownFocused = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
