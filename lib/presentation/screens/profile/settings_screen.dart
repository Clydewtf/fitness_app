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
  bool autoUpdateWeight = true;
  final UserSettingsStorage _storage = UserSettingsStorage();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final weightsInSets = await _storage.getRequireWeightsInSets();
    final autoUpdate = await _storage.getAutoUpdateWeight();
    setState(() {
      requireWeightsInSets = weightsInSets;
      autoUpdateWeight = autoUpdate;
    });
  }

  void _toggleRequireWeights(bool value) async {
    setState(() {
      requireWeightsInSets = value;
    });
    await _storage.setRequireWeightsInSets(value);
  }

  void _toggleAutoUpdateWeight(bool value) async {
    setState(() {
      autoUpdateWeight = value;
    });
    await _storage.setAutoUpdateWeight(value);
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
          ListTile(
            title: Text('Обновлять вес в профиле'),
            subtitle: Text('После тренировки / во вкладке прогресс вес будет сохраняться и становиться актуальным'),
            trailing: Switch(
              value: autoUpdateWeight,
              onChanged: _toggleAutoUpdateWeight,
            ),
          ),
        ],
      ),
    );
  }
}