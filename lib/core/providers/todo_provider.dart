import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final todayTodosProvider = FutureProvider<List<TodoItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final all = await (db.select(db.todoItems)
    ..where((t) => t.date.equals(today))
    ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])
  ).get();
  return all.where((t) => !t.isSkipped).toList();
});

final todayTodoStatsProvider = FutureProvider<TodoStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final all = await (db.select(db.todoItems)..where((t) => t.date.equals(today))).get();
  final todos = all.where((t) => !t.isSkipped).toList();
  final total = todos.length;
  final completed = todos.where((t) => t.isCompleted).length;
  return TodoStats(total: total, completed: completed);
});

class TodoStats {
  final int total;
  final int completed;
  TodoStats({required this.total, required this.completed});
}

const _defaultSuggestions = [
  '🙏 Pray', '📖 Read Bible', '💪 Exercise',
  '📚 Study', '📞 Call someone', '🧹 Clean',
];

Future<List<String>> loadSuggestions() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('taskSuggestions');
  if (json != null) {
    final list = json.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (list.isNotEmpty) return list;
  }
  return List.from(_defaultSuggestions);
}

Future<void> saveSuggestions(List<String> suggestions) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('taskSuggestions', suggestions.join('\n'));
}

class TodoNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> addTodo(String title) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.todoItems)..where((t) => t.date.equals(today))).get();
    await db.into(db.todoItems).insert(TodoItemsCompanion.insert(
      id: const Uuid().v4(),
      title: title,
      date: today,
      sortOrder: Value(existing.length),
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(todayTodosProvider);
    ref.invalidate(todayTodoStatsProvider);
    _scheduleEveningIfFirst();
  }

  Future<void> toggleTodo(String id) async {
    final db = ref.read(databaseProvider);
    final todo = await (db.select(db.todoItems)..where((t) => t.id.equals(id))).getSingle();
    final now = DateTime.now().toIso8601String();
    await (db.update(db.todoItems)..where((t) => t.id.equals(id))).write(TodoItemsCompanion(
      isCompleted: Value(!todo.isCompleted),
      completedAt: Value(!todo.isCompleted ? now : null),
    ));
    ref.invalidate(todayTodosProvider);
    ref.invalidate(todayTodoStatsProvider);
    ref.invalidate(trackingDataProvider);
    if (!todo.isCompleted) _cancelEveningIfAllDone();
  }

  Future<void> deleteTodo(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.todoItems)..where((t) => t.id.equals(id))).go();
    ref.invalidate(todayTodosProvider);
    ref.invalidate(todayTodoStatsProvider);
  }

  Future<void> saveReflection(String content) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.into(db.dailyReflections).insert(DailyReflectionsCompanion.insert(
      id: const Uuid().v4(),
      date: today,
      content: content,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<void> carryToTomorrow(String id) async {
    final db = ref.read(databaseProvider);
    final todo = await (db.select(db.todoItems)..where((t) => t.id.equals(id))).getSingle();
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final existing = await (db.select(db.todoItems)..where((t) => t.date.equals(tomorrow))).get();
    await db.into(db.todoItems).insert(TodoItemsCompanion.insert(
      id: const Uuid().v4(),
      title: todo.title,
      date: tomorrow,
      sortOrder: Value(existing.length),
      createdAt: DateTime.now().toIso8601String(),
    ));
    await (db.update(db.todoItems)..where((t) => t.id.equals(id))).write(const TodoItemsCompanion(
      isSkipped: Value(true),
    ));
    ref.invalidate(todayTodosProvider);
    ref.invalidate(todayTodoStatsProvider);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final all = await (db.select(db.todoItems)
      ..where((t) => t.date.equals(today))
      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])
    ).get();
    final todos = all.where((t) => !t.isSkipped).toList();
    if (oldIndex < 0 || oldIndex >= todos.length || newIndex < 0 || newIndex >= todos.length) return;
    final item = todos.removeAt(oldIndex);
    todos.insert(newIndex, item);
    for (int i = 0; i < todos.length; i++) {
      await (db.update(db.todoItems)..where((t) => t.id.equals(todos[i].id))).write(TodoItemsCompanion(sortOrder: Value(i)));
    }
    ref.invalidate(todayTodosProvider);
  }

  void _scheduleEveningIfFirst() async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final all = await (db.select(db.todoItems)..where((t) => t.date.equals(today))).get();
    final count = all.where((t) => !t.isSkipped).length;
    if (count == 1) {
      NotificationService.scheduleEveningReview();
    }
  }

  void _cancelEveningIfAllDone() async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final all = await (db.select(db.todoItems)..where((t) => t.date.equals(today))).get();
    final todos = all.where((t) => !t.isSkipped).toList();
    if (todos.every((t) => t.isCompleted)) {
      NotificationService.cancelEveningReview();
    }
  }
}

final todoNotifierProvider = AsyncNotifierProvider<TodoNotifier, void>(TodoNotifier.new);
