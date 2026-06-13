import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/widgets/task_tile.dart';
import '../app.dart';
import '../models/task.dart';
import '../services/task_storage.dart';

enum _SortOrder { newestFirst, oldestFirst }

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  static const _keySortOrder = 'all_tasks_sort_order';
  static const _keyPendingOnly = 'all_tasks_pending_only';

  Map<String, List<Task>> _tasksByDate = {};
  bool _loading = true;
  _SortOrder _sortOrder = _SortOrder.newestFirst;
  bool _pendingOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _loadAll());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortOrder = (prefs.getString(_keySortOrder) == 'oldestFirst')
          ? _SortOrder.oldestFirst
          : _SortOrder.newestFirst;
      _pendingOnly = prefs.getBool(_keyPendingOnly) ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySortOrder,
        _sortOrder == _SortOrder.newestFirst ? 'newestFirst' : 'oldestFirst');
    await prefs.setBool(_keyPendingOnly, _pendingOnly);
  }

  Future<void> _toggleTask(String dateStr, String taskId) async {
    final parts = dateStr.split('-');
    final date =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final tasks = _tasksByDate[dateStr]!.map((t) {
      return t.id == taskId ? t.copyWith(isCompleted: !t.isCompleted) : t;
    }).toList();
    await TaskStorage.saveTasks(date, tasks);
    setState(() => _tasksByDate[dateStr] = tasks);
  }

  Future<void> _deleteTask(String dateStr, String taskId) async {
    final parts = dateStr.split('-');
    final date =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final tasks = _tasksByDate[dateStr]!.where((t) => t.id != taskId).toList();
    await TaskStorage.saveTasks(date, tasks);
    setState(() {
      if (tasks.isEmpty) {
        _tasksByDate.remove(dateStr);
      } else {
        _tasksByDate[dateStr] = tasks;
      }
    });
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final dates = await TaskStorage.getAllDatesWithTasks();
    final sorted = dates.toList()..sort();
    final Map<String, List<Task>> result = {};
    for (final dateStr in sorted) {
      final parts = dateStr.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final tasks = await TaskStorage.loadTasks(date);
      if (tasks.isNotEmpty) result[dateStr] = tasks;
    }
    if (mounted) {
      setState(() {
        _tasksByDate = result;
        _loading = false;
      });
    }
  }

  List<String> get _sortedKeys {
    final keys = _tasksByDate.keys.toList()..sort();
    if (_sortOrder == _SortOrder.newestFirst) return keys.reversed.toList();
    return keys;
  }

  int get _completedCount =>
      _tasksByDate.values.expand((t) => t).where((t) => t.isCompleted).length;

  Future<void> _deleteAllDone() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete all done tasks?',
            style: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink)),
        content: const Text(
            'This will permanently remove completed tasks across all days.',
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
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'sans-serif'))),
        ],
      ),
    );
    if (confirm != true) return;

    for (final entry in _tasksByDate.entries) {
      final parts = entry.key.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final remaining = entry.value.where((t) => !t.isCompleted).toList();
      await TaskStorage.saveTasks(date, remaining);
    }
    await _loadAll();
  }

  bool _isToday(String dateStr) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return dateStr == todayStr;
  }

  String _formatDateHeader(String dateStr) {
    final parts = dateStr.split('-');
    final date =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return DateFormat('EEEE · MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.ink,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('All tasks',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'sans-serif')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.ink))
          : _tasksByDate.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildActionBar(),
                    _buildFilterBar(),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  Widget _buildActionBar() {
    final count = _completedCount;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            count == 0
                ? 'No completed tasks'
                : '$count completed across all days',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.muted, fontFamily: 'sans-serif'),
          ),
          const Spacer(),
          if (count > 0)
            GestureDetector(
              onTap: _deleteAllDone,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline,
                        size: 14, color: AppTheme.accent),
                    SizedBox(width: 4),
                    Text('Delete done',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'sans-serif')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: AppTheme.cream,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _sortOrder = _sortOrder == _SortOrder.newestFirst
                    ? _SortOrder.oldestFirst
                    : _SortOrder.newestFirst;
              });
              _savePrefs();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortOrder == _SortOrder.newestFirst
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _sortOrder == _SortOrder.newestFirst
                        ? 'Newest first'
                        : 'Oldest first',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'sans-serif'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() => _pendingOnly = !_pendingOnly);
              _savePrefs();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _pendingOnly ? AppTheme.accent : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _pendingOnly ? AppTheme.accent : AppTheme.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _pendingOnly
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank,
                    size: 13,
                    color: _pendingOnly ? Colors.white : AppTheme.muted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Pending only',
                    style: TextStyle(
                        fontSize: 12,
                        color: _pendingOnly ? Colors.white : AppTheme.muted,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'sans-serif'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final keys = _sortedKeys;
    final visibleKeys = _pendingOnly
        ? keys
            .where((k) => (_tasksByDate[k] ?? []).any((t) => !t.isCompleted))
            .toList()
        : keys;

    if (visibleKeys.isEmpty) {
      return const Center(
        child: Text('No pending tasks',
            style: TextStyle(
                color: AppTheme.muted, fontSize: 16, fontFamily: 'sans-serif')),
      );
    }

    return ListView.builder(
      itemCount: visibleKeys.length,
      itemBuilder: (context, i) {
        final dateStr = visibleKeys[i];
        final tasks = _tasksByDate[dateStr]!;
        final today = _isToday(dateStr);
        return _buildDateGroup(dateStr, tasks, today);
      },
    );
  }

  Widget _buildDateGroup(String dateStr, List<Task> tasks, bool isToday) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final done = tasks.where((t) => t.isCompleted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(
            children: [
              Text(
                _formatDateHeader(dateStr).toUpperCase(),
                style: TextStyle(
                  color: isToday ? AppTheme.ink : AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  fontFamily: 'sans-serif',
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('TODAY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontFamily: 'sans-serif')),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(child: Container(height: 0.5, color: AppTheme.divider)),
            ],
          ),
        ),
        ...pending.map((t) => TaskTile(
              key: ValueKey('all_${t.id}'),
              task: t,
              onToggle: () => _toggleTask(dateStr, t.id),
              onDelete: () => _deleteTask(dateStr, t.id),
              onTap: () {}, // editing not supported in this view
            )),
        ...done.map((t) => TaskTile(
              key: ValueKey('all_done_${t.id}'),
              task: t,
              onToggle: () => _toggleTask(dateStr, t.id),
              onDelete: () => _deleteTask(dateStr, t.id),
              onTap: () {},
            )),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('No tasks yet',
          style: TextStyle(
              color: AppTheme.muted, fontSize: 16, fontFamily: 'sans-serif')),
    );
  }
}
