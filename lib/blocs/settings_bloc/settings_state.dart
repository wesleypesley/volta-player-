part of 'settings_bloc.dart';

class SettingsState {
  final ThemeMode themeMode;
  final DownloadFormat defaultFormat;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.defaultFormat = DownloadFormat.best,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    DownloadFormat? defaultFormat,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      defaultFormat: defaultFormat ?? this.defaultFormat,
    );
  }
}
