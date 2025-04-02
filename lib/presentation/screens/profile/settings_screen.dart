import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки')),
      body: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          bool isDarkMode = state is ThemeUpdated && state.isDarkMode;
          return ListTile(
            title: Text('Темная тема'),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                context.read<ThemeCubit>().toggleTheme();
              },
            ),
          );
        },
      ),
    );
  }
}