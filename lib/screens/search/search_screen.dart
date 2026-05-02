import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/url_validator.dart';
import '../../services/database_service.dart';
import 'widgets/search_history_tile.dart';
import 'widgets/supported_sites_strip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _urlController = TextEditingController();
  List<Map<String, dynamic>> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseService.instance.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  void _onSearch(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    if (!UrlValidator.isValidUrl(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    // Save to history
    await DatabaseService.instance.addSearchHistory(trimmed);
    _loadHistory();

    // Navigate to Downloads with URL
    if (mounted) {
      final encodedUrl = Uri.encodeComponent(trimmed);
      context.go('/downloads?url=$encodedUrl');
      _urlController.clear();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Enter URL to download',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.bgElevatedDark
                          : AppColors.bgElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data != null && data.text != null) {
                            _urlController.text = data.text!;
                          }
                        },
                      ),
                    ),
                    onSubmitted: _onSearch,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: () => _onSearch(_urlController.text),
                  backgroundColor: AppColors.accent,
                  elevation: 0,
                  mini: true,
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          const SupportedSitesStrip(),
          const Divider(height: 32),
          Expanded(
            child: _searchHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No recent searches',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchHistory.length,
                    itemBuilder: (context, index) {
                      final item = _searchHistory[index];
                      return SearchHistoryTile(
                        url: item['url'] as String,
                        onTap: () {
                          _onSearch(item['url'] as String);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
