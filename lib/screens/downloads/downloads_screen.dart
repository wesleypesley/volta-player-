import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/url_validator.dart';
import '../../models/download_task.dart';
import '../../blocs/downloads_bloc/downloads_bloc.dart';
import '../../services/database_service.dart';
import 'widgets/url_input_bar.dart';
import 'widgets/download_progress_card.dart';
import 'widgets/format_picker_sheet.dart';

class DownloadsScreen extends StatefulWidget {
  final String? sharedUrl;

  const DownloadsScreen({super.key, this.sharedUrl});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applySharedUrl(widget.sharedUrl);
  }

  @override
  void didUpdateWidget(covariant DownloadsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sharedUrl != oldWidget.sharedUrl) {
      _applySharedUrl(widget.sharedUrl);
    }
  }

  void _applySharedUrl(String? url) {
    if (url == null || url.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _urlController.text = url;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL received')),
      );
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showFormatPicker() {
    if (_urlController.text.trim().isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FormatPickerSheet(
          onSelected: (format) {
            Navigator.pop(context);
            _startDownload(format);
          },
        );
      },
    );
  }

  Future<void> _startDownload(DownloadFormat format) async {
    final url = _urlController.text.trim();
    if (!UrlValidator.isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    await DatabaseService.instance.addSearchHistory(url);
    if (!mounted) return;
    context.read<DownloadsBloc>().add(AddDownload(url, format));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Queued for download: ${format.name}')),
    );
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: Column(
        children: [
          UrlInputBar(
            controller: _urlController,
            onDownload: _showFormatPicker,
          ),
          Expanded(
            child: BlocBuilder<DownloadsBloc, DownloadsState>(
              builder: (context, state) {
                if (state is DownloadsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DownloadsLoaded) {
                  final tasks = [...state.active, ...state.completed];
                  
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_done, size: 80, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'No active downloads',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return DownloadProgressCard(task: tasks[index]);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
