import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/downloads_bloc/downloads_bloc.dart';
import 'blocs/library_bloc/library_bloc.dart';
import 'blocs/player_bloc/player_bloc.dart';
import 'blocs/settings_bloc/settings_bloc.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';
import 'services/share_intent_service.dart';

class VoltaApp extends StatefulWidget {
  const VoltaApp({super.key});

  @override
  State<VoltaApp> createState() => _VoltaAppState();
}

class _VoltaAppState extends State<VoltaApp> {
  @override
  void initState() {
    super.initState();
    ShareIntentService.instance.init();
  }

  @override
  void dispose() {
    ShareIntentService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PlayerBloc()),
        BlocProvider(create: (_) => DownloadsBloc()..add(LoadDownloads())),
        BlocProvider(create: (_) => LibraryBloc()),
        BlocProvider(create: (_) => SettingsBloc()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: 'Volta Player',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
