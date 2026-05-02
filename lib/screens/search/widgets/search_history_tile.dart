import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class SearchHistoryTile extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const SearchHistoryTile({
    super.key,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history, color: AppColors.textTertiary),
      title: Text(
        url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
