import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app.dart';
import '../models/task.dart';
import '../services/task_storage.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  // Map of date string → task list, sorted by date
  Map<String, List<Task>> _tasksByDate = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
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
    if (mounted) setState(() { _tasksByDate = result; _loading = false; });
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
            style: TextStyle(fontFamily: 'sans-serif', fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.ink)),
        content: const Text('This will permanently remove completed tasks across all days.',
            style: TextStyle(fontFamily: 'sans-serif', color: AppTheme.muted, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.muted, fontFamily: 'sans-serif'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontFamily: 'sans-serif'))),
        ],
      ),
    );
    if (confirm != true) return;

    for (final entry in _tasksByDate.entries) {
      final parts = entry.key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
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
            style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.ink))
          : _tasksByDate.isEmpty
              ? _buildEmpty()
              : Column(
                  children: [
                    _buildActionBar(),
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
            count == 0 ? 'No completed tasks' : '$count completed across all days',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.muted, fontFamily: 'sans-serif'),
          ),
          const Spacer(),
          if (count > 0)
            GestureDetector(
              onTap: _deleteAllDone,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, size: 14, color: AppTheme.accent),
                    SizedBox(width: 4),
                    Text('Delete done',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.accent,
                            fontWeight: FontWeight.w600, fontFamily: 'sans-serif')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _tasksByDate.length,
      itemBuilder: (context, i) {
        final dateStr = _tasksByDate.keys.elementAt(i);
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('TODAY',
                      style: TextStyle(color: Colors.white, fontSize: 8,
                          fontWeight: FontWeight.w800, letterSpacing: 1.2, fontFamily: 'sans-serif')),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(child: Container(height: 0.5, color: AppTheme.divider)),
            ],
          ),
        ),
        ...pending.map((t) => _buildTaskRow(t, false)),
        ...done.map((t) => _buildTaskRow(t, true)),
      ],
    );
  }

  Widget _buildTaskRow(Task task, bool completed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: completed ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: completed ? [] : [
          BoxShadow(color: AppTheme.ink.withValues(alpha: 0.05),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: completed ? AppTheme.checkGreen : Colors.transparent,
                border: Border.all(
                    color: completed ? AppTheme.checkGreen : AppTheme.muted, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: completed
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(task.title,
                  style: TextStyle(
                    fontSize: 14, fontFamily: 'sans-serif',
                    color: completed ? AppTheme.muted : AppTheme.ink,
                    decoration: completed ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppTheme.muted,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('No tasks yet',
          style: TextStyle(color: AppTheme.muted, fontSize: 16, fontFamily: 'sans-serif')),
    );
  }
}
