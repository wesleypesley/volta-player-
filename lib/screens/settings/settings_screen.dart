import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/settings_bloc/settings_bloc.dart';
import '../../models/download_task.dart';
import '../../services/download_service.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DownloadFormat _defaultFormat = DownloadFormat.best;
  String _appVersion = '';
  String _updateStatus = 'Not checked';
  String _downloadPath = '';

  @override
  void initState() {
    super.initState();
    _appVersion = '1.0.0+1';
    StorageService.instance.getDownloadPath().then((path) {
      if (!mounted) return;
      setState(() => _downloadPath = path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settings) {
              return SwitchListTile(
                title: const Text('Dark mode'),
                subtitle: const Text('Uses system theme unless toggled here'),
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (value) => context.read<SettingsBloc>().add(
                    SetThemeMode(value ? ThemeMode.dark : ThemeMode.light)),
              );
            },
          ),
          ListTile(
            title: const Text('Default format'),
            subtitle: Text(_formatLabel(_defaultFormat)),
            trailing: DropdownButton<DownloadFormat>(
              value: _defaultFormat,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _defaultFormat = value);
                context.read<SettingsBloc>().add(SetDefaultFormat(value));
              },
              items: const [
                DropdownMenuItem(
                    value: DownloadFormat.audioOnly, child: Text('Audio MP3')),
                DropdownMenuItem(
                    value: DownloadFormat.videoMp4, child: Text('Video MP4')),
                DropdownMenuItem(
                    value: DownloadFormat.best, child: Text('Best')),
              ],
            ),
          ),
          ListTile(
            title: const Text('Download folder'),
            subtitle:
                Text(_downloadPath.isEmpty ? 'Loading...' : _downloadPath),
            leading: const Icon(Icons.folder),
            trailing: FilledButton.icon(
              onPressed: _browseDownloadPath,
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse'),
            ),
            onTap: _browseDownloadPath,
          ),
          ListTile(
            title: const Text('yt-dlp'),
            subtitle: Text(_updateStatus),
            trailing: TextButton(
              onPressed: () async {
                setState(() => _updateStatus = 'Checking...');
                try {
                  await DownloadService.instance.updateYoutubeDL();
                  if (!mounted) return;
                  setState(() => _updateStatus = 'Updated and ready');
                } catch (error) {
                  if (!mounted) return;
                  setState(() => _updateStatus = 'Update failed: $error');
                }
              },
              child: const Text('Check'),
            ),
          ),
          const ListTile(
            title: Text('FFmpeg license'),
            subtitle: Text(
                'FFmpeg components are used for media conversion and metadata workflows.'),
          ),
          ListTile(
            title: const Text('App version'),
            subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
          ),
          const AboutListTile(
            applicationName: 'Volta Player',
            applicationVersion: '1.0.0',
            child: Text('About'),
          ),
        ],
      ),
    );
  }

  String _formatLabel(DownloadFormat format) {
    switch (format) {
      case DownloadFormat.audioOnly:
        return 'Audio MP3';
      case DownloadFormat.videoMp4:
        return 'Video MP4';
      case DownloadFormat.best:
        return 'Best';
    }
  }

  Future<void> _browseDownloadPath() async {
    final selectedPath = await StorageService.instance.pickDownloadPath();
    if (!mounted || selectedPath == null) return;
    setState(() => _downloadPath = selectedPath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download folder set to $selectedPath')),
    );
  }
}
