import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/locator.dart';
import '../../../data/models/photo_progress_entry.dart';
import '../../../data/repositories/body_log_repository.dart';
import '../../../data/repositories/photo_progress_repository.dart';
import '../../../data/repositories/workout_log_repository.dart';
import '../../../logic/progress_bloc/photo_progress_cubit.dart';
import '../../../services/achievement_service.dart';
import '../../../services/auth_service.dart';
import '../../widgets/progress/photo_full_screen.dart';

class PhotoProgressWrapper extends StatelessWidget {
  const PhotoProgressWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PhotoProgressCubit>()..loadEntries(),
      child: const PhotoProgressScreen(),
    );
  }
}

class PhotoProgressScreen extends StatelessWidget {
  const PhotoProgressScreen({super.key});

  Future<void> _pickAndAddPhoto(BuildContext context) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final result = await picker.pickImage(source: source, imageQuality: 85);
    if (result != null && context.mounted) {
      final cubit = context.read<PhotoProgressCubit>();

      final pose = await showDialog<String>(
        context: context,
        builder: (_) => _PoseSelectionDialog(),
      );

      if (pose == null) return;

      final path = await cubit.repository.saveImageFile(File(result.path));

      final entry = PhotoProgressEntry(
        path: path,
        date: DateTime.now(),
        pose: pose,
      );

      await cubit.addEntry(entry);

      // ⬇️ Обновляем ачивки
      final uid = AuthService().getCurrentUser()?.uid;
      if (uid == null) return;

      final workoutLogs = await WorkoutLogRepository().getWorkoutLogs(uid);
      final photoLogs = await PhotoProgressRepository().loadEntries();
      final bodyLogs = await BodyLogRepository(
        firestore: FirebaseFirestore.instance,
        userId: uid,
      ).loadLogs();

      await AchievementService().checkAndUpdateAchievements(
        workoutLogs: workoutLogs,
        photoEntries: photoLogs,
        bodyLogs: bodyLogs,
      );
    }
  }

  void _showDeleteDialog(BuildContext context, PhotoProgressEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить фото?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<PhotoProgressCubit>().deleteEntry(entry);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final cubit = context.read<PhotoProgressCubit>();
    final currentPose = cubit.state.poseFilter ?? 'Все';
    final currentRange = cubit.state.dateRange;

    String selectedPose = currentPose;
    DateTimeRange? selectedRange = currentRange;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Фильтры'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedPose,
                    items: ['Все', 'Спереди', 'Сбоку', 'Спина', 'Ноги', 'Другое']
                        .map((pose) => DropdownMenuItem(
                              value: pose,
                              child: Text(pose),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedPose = value ?? 'Все');
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: selectedRange,
                      );
                      if (picked != null) {
                        setState(() => selectedRange = picked);
                      }
                    },
                    child: Text(selectedRange == null
                        ? 'Выбрать диапазон дат'
                        : '${selectedRange!.start.day}.${selectedRange!.start.month}.${selectedRange!.start.year} - ${selectedRange!.end.day}.${selectedRange!.end.month}.${selectedRange!.end.year}'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cubit.clearFilters();
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                cubit.applyFilters(
                  pose: selectedPose == 'Все' ? null : selectedPose,
                  range: selectedRange,
                );
              },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PhotoProgressCubit, PhotoProgressState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Фото-прогресс'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _pickAndAddPhoto(context),
            child: const Icon(Icons.add),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.filteredEntries.isEmpty
                  ? const Center(child: Text('Фото не найдены'))
                  : _buildGroupedView(state.filteredEntries),
        );
      },
    );
  }

  Widget _buildGroupedView(List<PhotoProgressEntry> entries) {
    final sorted = entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // новые фото сверху

    final grouped = <String, List<PhotoProgressEntry>>{};

    for (final entry in sorted) {
      final key = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: grouped.entries.map((e) {
        final dateParts = e.key.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final title = '${_monthName(month)} $year';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: e.value.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final entry = e.value[index];
                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(context, entry),
                  onTap: () async {
                    final deleted = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => PhotoFullScreen(imagePath: entry.path),
                      ),
                    );
                    if (deleted == true && context.mounted) {
                      context.read<PhotoProgressCubit>().deleteEntry(entry);
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.file(
                          File(entry.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: Colors.black54,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.date.day}.${entry.date.month}.${entry.date.year}',
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                              Text(
                                entry.pose,
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  String _monthName(int month) {
    const months = [
      '', // dummy для 0
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
    ];
    return months[month];
  }
}

class _PoseSelectionDialog extends StatelessWidget {
  final poses = [
    'Спереди',
    'Сбоку',
    'Спина',
    'Ноги',
    'Другое',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите ракурс'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: poses.length,
          itemBuilder: (context, index) {
            final pose = poses[index];
            return ListTile(
              title: Text(pose),
              onTap: () => Navigator.pop(context, pose),
            );
          },
        ),
      ),
    );
  }
}