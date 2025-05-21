import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool requireWeightsInSets = true;
  final UserSettingsStorage _storage = UserSettingsStorage();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final value = await _storage.getRequireWeightsInSets();
    setState(() {
      requireWeightsInSets = value;
    });
  }

  void _toggleRequireWeights(bool value) async {
    setState(() {
      requireWeightsInSets = value;
    });
    await _storage.setRequireWeightsInSets(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки')),
      body: Column(
        children: [
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              bool isDarkMode = state is ThemeUpdated && state.isDarkMode;
              return ListTile(
                title: Text('Тёмная тема'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (value) {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                ),
              );
            },
          ),
          ListTile(
            title: Text('Запрашивать вес для подходов'),
            subtitle: Text('Показывать ввод веса после тренировки'),
            trailing: Switch(
              value: requireWeightsInSets,
              onChanged: _toggleRequireWeights,
            ),
          ),
        ],
      ),
    );
  }
}