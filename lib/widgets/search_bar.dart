import 'package:flutter/material.dart';
import '../widgets/colors.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(List<dynamic>) onSearchResults;
  final List<dynamic> books;
  final ValueChanged<bool> onFocusChange;
  final FocusNode focusNode;
  final FocusNode dropdownFocusNode;

  CustomSearchBar({
    required this.onSearchResults,
    required this.books,
    required this.onFocusChange,
    required this.focusNode,
    required this.dropdownFocusNode,
  });

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'inTitle';
  bool _isTextFieldFocused = false;
  bool _isDropdownFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        default:
          fieldToSearch = book['title'];
      }
      return fieldToSearch.toLowerCase().contains(keyword.toLowerCase());
    }).toList();

    widget.onSearchResults(searchResults);
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event.runtimeType.toString() == 'RawKeyDownEvent') {
      if (widget.focusNode.hasFocus) {
        if (event.logicalKey.keyLabel == 'Arrow Down') {
          widget.focusNode.unfocus();
          FocusScope.of(context).requestFocus(widget.dropdownFocusNode);
        }
      } else if (widget.dropdownFocusNode.hasFocus) {
        if (event.logicalKey.keyLabel == 'Arrow Up') {
          widget.dropdownFocusNode.unfocus();
          FocusScope.of(context).requestFocus(widget.focusNode);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyPress,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Focus(
                focusNode: widget.focusNode,
                onFocusChange: (isFocused) {
                  widget.onFocusChange(isFocused);
                  setState(() {
                    _isTextFieldFocused = isFocused;
                  });
                  if (!isFocused && _searchController.text.isEmpty) {
                    widget.onSearchResults([]);
                  }
                },
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _isTextFieldFocused = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isTextFieldFocused = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isTextFieldFocused ? Colors.blue : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
                    child: TextField(
                      cursorColor: Colors.white,
                      controller: _searchController,
                      style: TextStyle(color: AppColors.textColor),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search, color: AppColors.iconColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onChanged: (value) {
                        _searchBooks(value);
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Focus(
                focusNode: widget.dropdownFocusNode,
                onFocusChange: (isFocused) {
                  widget.onFocusChange(isFocused);
                  setState(() {
                    _isDropdownFocused = isFocused;
                  });
                },
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _isDropdownFocused = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isDropdownFocused = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isDropdownFocused ? Colors.blue : Colors.transparent,
                        width: 2.0,
                      ),
                    ),
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
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onTap: () {
                        widget.onFocusChange(true);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
