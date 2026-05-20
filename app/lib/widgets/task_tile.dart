import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app.dart';
import '../models/task.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  bool _isEditing = false;
  late TextEditingController _editController;

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
    _editController = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _checkController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _onToggle() async {
    HapticFeedback.lightImpact();
    await _checkController.forward();
    await _checkController.reverse();
    widget.onToggle();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _editController.text = widget.task.title;
    _editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.task.title.length,
    );
  }

  void _submitEdit() {
    setState(() => _isEditing = false);
    widget.onEdit(_editController.text);
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
        onDoubleTap: _startEditing,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: widget.task.isCompleted
                ? Colors.white.withOpacity(0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.task.isCompleted
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.ink.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isEditing ? null : () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _checkScale,
                      child: GestureDetector(
                        onTap: _onToggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
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
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _editController,
                              autofocus: true,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 15,
                                fontFamily: 'sans-serif',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _submitEdit(),
                              onTapOutside: (_) => _submitEdit(),
                            )
                          : AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
