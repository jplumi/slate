import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app.dart';
import '../models/task.dart';
import '../services/task_storage.dart';
import '../widgets/task_tile.dart';
import '../widgets/add_task_sheet.dart';

extension _IntLet on int {
  T let<T>(T Function(int) f) => f(this);
}

class DayScreen extends StatefulWidget {
  final DateTime date;

  const DayScreen({super.key, required this.date});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant DayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final tasks = await TaskStorage.loadTasks(widget.date);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    }
  }

  Future<void> _saveTasks() async {
    await TaskStorage.saveTasks(widget.date, _tasks);
  }

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      createdAt: DateTime.now(),
    );
    setState(() => _tasks.add(task));
    _saveTasks();
  }

  void _toggleTask(String id) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          isCompleted: !_tasks[index].isCompleted,
        );
      }
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((t) => t.id == id));
    _saveTasks();
  }

  void showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(onAdd: _addTask),
    );
  }

  void _showEditSheet(String id, String currentTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialValue: currentTitle,
        onAdd: (newTitle) => _editTask(id, newTitle),
      ),
    );
  }

  void _editTask(String id, String newTitle) {
    if (newTitle.trim().isEmpty) {
      _deleteTask(id);
      return;
    }
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(title: newTitle.trim());
      }
    });
    _saveTasks();
  }

  int get _completedCount => _tasks.where((t) => t.isCompleted).length;
  List<Task> get _pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get _completedTasks => _tasks.where((t) => t.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tap anywhere on empty area to add task
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.ink))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_tasks.isEmpty) {
      return _buildEmptyState();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: showAddSheet,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          if (_pendingTasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                '${_pendingTasks.length} task${_pendingTasks.length == 1 ? '' : 's'} to do',
                false,
              ),
            ),
            SliverReorderableList(
              itemCount: _pendingTasks.length,
              onReorder: _reorderTasks,
              itemBuilder: (context, index) {
                final task = _pendingTasks[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(task.id),
                  index: index,
                  child: TaskTile(
                    key: ValueKey('tile_${task.id}'),
                    task: task,
                    onToggle: () => _toggleTask(task.id),
                    onDelete: () => _deleteTask(task.id),
                    onTap: () => _showEditSheet(task.id, task.title),
                  ),
                );
              },
            ),
          ],
          if (_completedTasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                '$_completedCount done',
                true,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = _completedTasks[index];
                  return TaskTile(
                    key: ValueKey(task.id),
                    task: task,
                    onToggle: () => _toggleTask(task.id),
                    onDelete: () => _deleteTask(task.id),
                    onTap: () => _showEditSheet(task.id, task.title),
                  );
                },
                childCount: _completedTasks.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: completed ? AppTheme.checkGreen : AppTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              fontFamily: 'sans-serif',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: completed
                  ? AppTheme.checkGreen.withValues(alpha: 0.3)
                  : AppTheme.divider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: showAddSheet,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_task_rounded,
                size: 32,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks yet',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'sans-serif',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap anywhere to add your first task',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 14,
                fontFamily: 'sans-serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final task = _pendingTasks[oldIndex];
      // Work on the full _tasks list
      final fullOldIndex = _tasks.indexOf(task);
      _tasks.removeAt(fullOldIndex);
      // Find insertion point in full list (before completed tasks)
      final targetTask =
          newIndex < _pendingTasks.length ? _pendingTasks[newIndex] : null;
      final fullNewIndex = targetTask != null
          ? _tasks.indexOf(targetTask)
          : _tasks
              .indexWhere((t) => t.isCompleted)
              .let((i) => i == -1 ? _tasks.length : i);
      _tasks.insert(fullNewIndex, task);
    });
    _saveTasks();
  }
}
