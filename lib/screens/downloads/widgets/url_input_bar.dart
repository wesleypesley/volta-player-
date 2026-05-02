import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';

class UrlInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDownload;

  const UrlInputBar({
    super.key,
    required this.controller,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Paste media URL here...',
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
                      controller.text = data.text!;
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: onDownload,
            backgroundColor: AppColors.accent,
            elevation: 0,
            child: const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
