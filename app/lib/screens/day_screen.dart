import 'dart:async';

import 'package:flutter/material.dart';
import 'package:slate/services/sync_service.dart';
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
  final SyncService syncService;
  final bool tapAnywhereToAdd;

  const DayScreen(
      {super.key,
      required this.date,
      required this.syncService,
      required this.tapAnywhereToAdd});

  @override
  State<DayScreen> createState() => DayScreenState();
}

class DayScreenState extends State<DayScreen> {
  List<Task> _tasks = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  final _uuid = const Uuid();

  bool get _selectionMode => _selectedIds.isNotEmpty;

  StreamSubscription<void>? _syncSub;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _syncSub = widget.syncService.onSyncComplete.listen((_) => _loadTasks());
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _selectedIds.clear();
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _selectedIds.clear();
    });
    final tasks = await TaskStorage.loadTasks(widget.date);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    }
  }

  void addTask(String title) {
    if (title.trim().isEmpty) return;
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      date: widget.date,
      sortOrder: _tasks.length,
    );
    setState(() => _tasks.add(task));
    TaskStorage.saveTask(task);
    widget.syncService.scheduleSync();
  }

  void _toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated =
        _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
    setState(() => _tasks[index] = updated);
    TaskStorage.saveTask(updated);
    widget.syncService.scheduleSync();
  }

  void _selectTask(String id) {
    setState(() => _selectedIds.add(id));
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _exitSelection() {
    setState(() => _selectedIds.clear());
  }

  void _onTaskTap(Task task) {
    if (_selectionMode) {
      _toggleSelected(task.id);
    } else {
      _showEditSheet(task.id, task.title);
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    final label = ids.length == 1 ? 'task' : 'tasks';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${ids.length} $label?',
            style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        content: const Text(
            'This will permanently remove the selected tasks.',
            style: TextStyle(
                fontFamily: 'sans-serif', color: AppTheme.muted, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppTheme.muted, fontFamily: 'sans-serif'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(
                      color: AppTheme.accentRed,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'sans-serif'))),
        ],
      ),
    );
    if (confirm != true) return;

    await TaskStorage.deleteTasks(ids);
    widget.syncService.scheduleSync();
    if (!mounted) return;
    setState(() {
      _tasks.removeWhere((t) => ids.contains(t.id));
      _selectedIds.clear();
    });
  }

  void _deleteTask(String id) {
    setState(() => _tasks.removeWhere((t) => t.id == id));
    TaskStorage.deleteTask(id);
    widget.syncService.scheduleSync();
  }

  void showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(onAdd: addTask),
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
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = _tasks[index].copyWith(title: newTitle.trim());
    setState(() => _tasks[index] = updated);
    TaskStorage.saveTask(updated);
    widget.syncService.scheduleSync();
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
        backgroundColor: AppTheme.ink,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                color: Colors.white,
                onRefresh: widget.syncService.syncNow,
                child: _buildBody(),
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_tasks.isEmpty) {
      return _buildEmptyState();
    }

    final List<Widget> slivers = [
      if (_pendingTasks.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            '${_pendingTasks.length} task${_pendingTasks.length == 1 ? '' : 's'} to do',
            false,
          ),
        ),
        SliverReorderableList(
          itemCount: _pendingTasks.length,
          onReorderItem: _reorderTasks,
          itemBuilder: (context, index) {
            final task = _pendingTasks[index];
            return TaskTile(
              key: ValueKey(task.id),
              task: task,
              onToggle: () => _toggleTask(task.id),
              onTap: () => _onTaskTap(task),
              onLongPress: () => _selectTask(task.id),
              selectionMode: _selectionMode,
              selected: _selectedIds.contains(task.id),
              reorderIndex: _selectionMode ? null : index,
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
                onTap: () => _onTaskTap(task),
                onLongPress: () => _selectTask(task.id),
                selectionMode: _selectionMode,
                selected: _selectedIds.contains(task.id),
              );
            },
            childCount: _completedTasks.length,
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];

    final list = CustomScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      slivers: slivers,
    );

    Widget content = list;
    if (widget.tapAnywhereToAdd && !_selectionMode) {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: showAddSheet,
        child: list,
      );
    }

    if (!_selectionMode) return content;

    return Column(
      children: [
        _buildSelectionToolbar(),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildSelectionToolbar() {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      color: AppTheme.inkLight,
      child: Row(
        children: [
          IconButton(
            onPressed: _exitSelection,
            icon: const Icon(Icons.close, color: AppTheme.neutralLight),
            tooltip: 'Cancel selection',
          ),
          Text(
            '$count selected',
            style: const TextStyle(
              color: AppTheme.neutralLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'sans-serif',
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _confirmDeleteSelected,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppTheme.accentRed),
            label: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'sans-serif')),
          ),
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
    final content =
        ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      Center(
        child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
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
            )),
      )
    ]);

    if (!widget.tapAnywhereToAdd) {
      return content;
    }

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: showAddSheet,
        child: content);
  }

  void _reorderTasks(int oldIndex, int newIndex) {
    setState(() {
      final task = _pendingTasks[oldIndex];
      final fullOldIndex = _tasks.indexOf(task);
      _tasks.removeAt(fullOldIndex);
      final targetTask =
          newIndex < _pendingTasks.length ? _pendingTasks[newIndex] : null;
      final fullNewIndex = targetTask != null
          ? _tasks.indexOf(targetTask)
          : _tasks
              .indexWhere((t) => t.isCompleted)
              .let((i) => i == -1 ? _tasks.length : i);
      _tasks.insert(fullNewIndex, task);

      for (var i = 0; i < _tasks.length; i++) {
        _tasks[i] = _tasks[i].copyWith(sortOrder: i);
      }
    });
    TaskStorage.saveTasks(_tasks);
    widget.syncService.scheduleSync();
  }
}
