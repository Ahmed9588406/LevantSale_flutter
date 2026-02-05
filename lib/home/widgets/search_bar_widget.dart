import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/notifications_screen.dart';
import 'search_results_overlay.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;
  bool _showResults = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _currentQuery.isEmpty) {
        setState(() {
          _showResults = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
      _showResults = query.trim().isNotEmpty;
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _currentQuery = query.trim();
        _showResults = true;
      });
    }
  }

  void _closeSearchResults() {
    setState(() {
      _showResults = false;
      _searchController.clear();
      _currentQuery = '';
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Notification icon
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          'icons/notification.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF2B2B2A),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Search bar
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    textDirection: TextDirection.rtl,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'دور على موبايلات، عقارات، سيارات...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 14,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? InkWell(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Icon(
                                Icons.clear,
                                color: Color(0xFFB0B0B0),
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                _onSearchSubmitted(_searchController.text);
                              },
                              child: const Icon(
                                Icons.search,
                                color: Color(0xFF2B2B2A),
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search results overlay
        if (_showResults && _currentQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: SearchResultsOverlay(
              searchQuery: _currentQuery,
              onClose: _closeSearchResults,
              onSearchChanged: _onSearchChanged,
            ),
          ),
      ],
    );
  }
}
