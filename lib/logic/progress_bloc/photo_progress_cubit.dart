import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/photo_progress_entry.dart';
import '../../data/repositories/photo_progress_repository.dart';

// class PhotoProgressState {
//   final List<PhotoProgressEntry> entries;
//   final bool isLoading;

//   PhotoProgressState({
//     required this.entries,
//     required this.isLoading,
//   });

//   factory PhotoProgressState.initial() =>
//       PhotoProgressState(entries: [], isLoading: true);
// }

// class PhotoProgressCubit extends Cubit<PhotoProgressState> {
//   final PhotoProgressRepository repository;

//   PhotoProgressCubit({required this.repository})
//       : super(PhotoProgressState.initial()) {
//     loadEntries();
//   }

//   Future<void> loadEntries() async {
//     emit(PhotoProgressState(entries: state.entries, isLoading: true));
//     final entries = await repository.loadEntries();
//     emit(PhotoProgressState(entries: entries, isLoading: false));
//   }

//   Future<void> addEntry(PhotoProgressEntry entry) async {
//     final updated = List<PhotoProgressEntry>.from(state.entries)..add(entry);
//     await repository.saveEntries(updated);
//     emit(PhotoProgressState(entries: updated, isLoading: false));
//   }

//   Future<void> deleteEntry(PhotoProgressEntry entry) async {
//     await repository.deleteEntry(entry);
//     final updated = List<PhotoProgressEntry>.from(state.entries)
//       ..removeWhere((e) => e.path == entry.path);
//     emit(PhotoProgressState(entries: updated, isLoading: false));
//   }
// }

class PhotoProgressState {
  final List<PhotoProgressEntry> allEntries;
  final List<PhotoProgressEntry> filteredEntries;
  final bool isLoading;
  final String? poseFilter;
  final DateTimeRange? dateRange;

  PhotoProgressState({
    required this.allEntries,
    required this.filteredEntries,
    this.isLoading = false,
    this.poseFilter,
    this.dateRange,
  });

  PhotoProgressState copyWith({
    List<PhotoProgressEntry>? allEntries,
    List<PhotoProgressEntry>? filteredEntries,
    bool? isLoading,
    String? poseFilter,
    DateTimeRange? dateRange,
  }) {
    return PhotoProgressState(
      allEntries: allEntries ?? this.allEntries,
      filteredEntries: filteredEntries ?? this.filteredEntries,
      isLoading: isLoading ?? this.isLoading,
      poseFilter: poseFilter,
      dateRange: dateRange,
    );
  }
}

class PhotoProgressCubit extends Cubit<PhotoProgressState> {
  final PhotoProgressRepository repository;

  PhotoProgressCubit({required this.repository})
      : super(PhotoProgressState(allEntries: [], filteredEntries: []));

  Future<void> loadEntries() async {
    emit(state.copyWith(isLoading: true));
    final entries = await repository.loadEntries();

    emit(
      state.copyWith(
        allEntries: entries,
        filteredEntries: entries,
        isLoading: false,
      ),
    );
  }

  Future<void> addEntry(PhotoProgressEntry entry) async {
    final currentEntries = await repository.loadEntries();

    final updated = [...currentEntries, entry];
    await repository.saveEntries(updated);

    emit(state.copyWith(allEntries: updated));
    _applyFilters(updated);
  }

  Future<void> deleteEntry(PhotoProgressEntry entry) async {
    final currentEntries = await repository.loadEntries();

    final updated = [...currentEntries]..remove(entry);
    await repository.saveEntries(updated);

    emit(state.copyWith(allEntries: updated));
    _applyFilters(updated);
  }

  void setPoseFilter(String? pose) {
    emit(state.copyWith(poseFilter: pose));
  }

  void setDateRange(DateTimeRange? range) {
    emit(state.copyWith(dateRange: range));
  }

  void _applyFilters([List<PhotoProgressEntry>? base]) {
    final entries = base ?? state.allEntries;
    final pose = state.poseFilter;
    final range = state.dateRange;

    var filtered = entries;

    if (pose != null && pose != 'Все') {
      filtered = filtered.where((e) => e.pose == pose).toList();
    }

    if (range != null) {
      final start = DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(range.end.year, range.end.month, range.end.day);
      filtered = filtered.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    }

    emit(state.copyWith(filteredEntries: filtered));
  }

  void clearFilters() {
    emit(state.copyWith(poseFilter: null, dateRange: null));
    _applyFilters();
  }

  void applyFilters({String? pose, DateTimeRange? range}) {
    emit(state.copyWith(
      poseFilter: pose,
      dateRange: range,
    ));
    _applyFilters();
  }
}