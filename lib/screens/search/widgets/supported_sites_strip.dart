import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class SupportedSitesStrip extends StatelessWidget {
  const SupportedSitesStrip({super.key});

  final List<Map<String, dynamic>> _sites = const [
    {'name': 'YouTube', 'icon': Icons.play_circle_filled, 'color': Colors.red},
    {'name': 'SoundCloud', 'icon': Icons.cloud, 'color': Colors.orange},
    {'name': 'Twitter', 'icon': Icons.flutter_dash, 'color': Colors.blue},
    {'name': 'Instagram', 'icon': Icons.camera_alt, 'color': Colors.purple},
    {'name': 'TikTok', 'icon': Icons.music_note, 'color': Colors.black},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Supported Sites',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _sites.length,
            itemBuilder: (context, index) {
              final site = _sites[index];
              return Container(
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.bgElevatedDark
                            : AppColors.bgElevated,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(site['icon'], color: site['color']),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      site['name'],
                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
