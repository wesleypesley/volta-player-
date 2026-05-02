import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../models/download_task.dart';
part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<SetThemeMode>((event, emit) => emit(state.copyWith(themeMode: event.themeMode)));
    on<SetDefaultFormat>((event, emit) => emit(state.copyWith(defaultFormat: event.format)));
  }
}
