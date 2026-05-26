import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../models/task.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap; // opens edit sheet

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _checkScale = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _onToggle() {
    HapticFeedback.lightImpact();
    widget.onToggle();
    _checkController.forward().then((_) => _checkController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.accent,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        widget.onDelete();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: widget.task.isCompleted
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.task.isCompleted
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _checkScale,
                    child: GestureDetector(
                      onTap: _onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.task.isCompleted
                              ? AppTheme.checkGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: widget.task.isCompleted
                                ? AppTheme.checkGreen
                                : AppTheme.muted,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: widget.task.isCompleted
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 80),
                      style: TextStyle(
                        color: widget.task.isCompleted
                            ? AppTheme.muted
                            : AppTheme.ink,
                        fontSize: 15,
                        fontFamily: 'sans-serif',
                        height: 1.4,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppTheme.muted,
                      ),
                      child: Text(widget.task.title),
                    ),
                  ),
                  // subtle edit hint icon
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppTheme.muted.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
