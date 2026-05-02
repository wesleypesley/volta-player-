part of 'settings_bloc.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class SetThemeMode extends SettingsEvent {
  final ThemeMode themeMode;
  const SetThemeMode(this.themeMode);
}

class SetDefaultFormat extends SettingsEvent {
  final DownloadFormat format;
  const SetDefaultFormat(this.format);
}
