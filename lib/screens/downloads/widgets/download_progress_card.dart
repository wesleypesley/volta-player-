import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../models/download_task.dart';
import '../../../blocs/downloads_bloc/downloads_bloc.dart';

class DownloadProgressCard extends StatelessWidget {
  final DownloadTask task;

  const DownloadProgressCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.bgElevatedDark
          : AppColors.bgElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.status == DownloadStatus.downloading || task.status == DownloadStatus.converting
                    ? task.progress
                    : (task.status == DownloadStatus.complete ? 1.0 : 0.0),
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.status == DownloadStatus.failed ? AppColors.error : AppColors.accent,
                ),
                minHeight: 6,
              ),
            ),
            
            // Speed and ETA
            if (task.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.speedDisplay ?? 'Calculating...',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    task.etaDisplay ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            
            // Error Message
            if (task.status == DownloadStatus.failed && task.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                task.errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ],

            // Action Buttons
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.queued)
                  TextButton(
                    onPressed: () => context.read<DownloadsBloc>().add(CancelDownload(task.id)),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                  ),
                if (task.status == DownloadStatus.failed)
                  TextButton(
                    onPressed: () => context.read<DownloadsBloc>().add(RetryDownload(task.id)),
                    child: const Text('Retry', style: TextStyle(color: AppColors.accent)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;

    switch (task.status) {
      case DownloadStatus.queued:
        color = AppColors.warning;
        label = 'Queued';
        break;
      case DownloadStatus.downloading:
        color = AppColors.accent;
        label = '${(task.progress * 100).toStringAsFixed(1)}%';
        break;
      case DownloadStatus.converting:
        color = AppColors.accentVibrant;
        label = 'Converting';
        break;
      case DownloadStatus.complete:
        color = AppColors.success;
        label = 'Complete';
        break;
      case DownloadStatus.failed:
        color = AppColors.error;
        label = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
