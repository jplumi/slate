import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../models/task.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback onTap; // opens edit sheet
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;
  final int? reorderIndex;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onDelete,
    required this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectionMode = false,
    this.reorderIndex,
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
    final tile = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: widget.task.isCompleted
              ? AppTheme.inkLight.withValues(alpha: 0.5)
              : AppTheme.inkLight,
          borderRadius: BorderRadius.circular(14),
          border: widget.selected
              ? Border.all(color: AppTheme.accentRed, width: 1.5)
              : null,
          boxShadow: widget.task.isCompleted
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.inkLight.withValues(alpha: 0.06),
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
                          : AppTheme.neutralLight,
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
                if (widget.selectionMode) _buildSelectionIndicator(),
                if (!widget.selectionMode && widget.reorderIndex != null)
                  ReorderableDragStartListener(
                    index: widget.reorderIndex!,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.drag_handle,
                          size: 20, color: AppTheme.muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final onDelete = widget.onDelete;
    if (onDelete == null) return tile;

    return Dismissible(
      key: ValueKey(widget.task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.accentRed,
        child: const Icon(Icons.delete_outline, color: Colors.black, size: 24),
      ),
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      child: tile,
    );
  }

  Widget _buildSelectionIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: widget.selected ? AppTheme.accentRed : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.selected ? AppTheme.accentRed : AppTheme.muted,
            width: 1.5,
          ),
        ),
        child: widget.selected
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}
