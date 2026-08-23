import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slate/screens/sync_error_screen.dart';
import '../app.dart';
import '../services/sync_service.dart';
import '../widgets/calendar_panel.dart';
import 'day_screen.dart';
import 'all_tasks_screen.dart';

class DesktopHomeScreen extends StatefulWidget {
  final SyncService syncService;

  const DesktopHomeScreen({super.key, required this.syncService});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final _dayScreenKey = GlobalKey<DayScreenState>();
  final _composerController = TextEditingController();

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _submitComposer() {
    final text = _composerController.text.trim();
    if (text.isEmpty) return;
    _dayScreenKey.currentState?.addTask(text);
    _composerController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Row(
        children: [
          _buildSidebar(),
          const VerticalDivider(width: 1, color: AppTheme.divider),
          Expanded(
            child: Column(
              children: [
                _buildDayHeader(),
                _buildComposer(),
                Expanded(
                  child: DayScreen(
                    key: _dayScreenKey,
                    date: _selectedDate,
                    syncService: widget.syncService,
                    tapAnywhereToAdd: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'SLATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontFamily: 'sans-serif',
                  ),
                ),
                const Spacer(),
                _buildSyncDot(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CalendarPanel(
            selectedDate: _selectedDate,
            onDaySelected: _selectDate,
          ),
          const Divider(color: AppTheme.divider, height: 24),
          ListTile(
            leading: const Icon(Icons.today_rounded, color: Colors.white),
            title: const Text('Today',
                style:
                    TextStyle(color: Colors.white, fontFamily: 'sans-serif')),
            onTap: () => _selectDate(DateTime.now()),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_rounded, color: Colors.white),
            title: const Text('All tasks',
                style:
                    TextStyle(color: Colors.white, fontFamily: 'sans-serif')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllTasksScreen(syncService: widget.syncService),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDot() {
    return AnimatedBuilder(
      animation: widget.syncService,
      builder: (context, _) {
        if (widget.syncService.isSyncing) {
          return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }
        return GestureDetector(
          onTap: () {
            if (widget.syncService.hasError) {
              _openSyncErrors();
            } else {
              widget.syncService.syncNow();
            }
          },
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.syncService.hasError
                  ? AppTheme.accentRed
                  : AppTheme.checkGreen,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayHeader() {
    final isToday = _isToday(_selectedDate);
    return Container(
      color: AppTheme.ink,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'sans-serif',
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentRed,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('TODAY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontFamily: 'sans-serif')),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.inkLight,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, color: AppTheme.muted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _composerController,
                style: const TextStyle(
                  color: AppTheme.neutralLight,
                  fontSize: 14,
                  fontFamily: 'sans-serif',
                ),
                decoration: const InputDecoration(
                  hintText: 'Add a task and press Enter…',
                  hintStyle: TextStyle(
                    color: AppTheme.muted,
                    fontFamily: 'sans-serif',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _submitComposer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSyncErrors() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SyncErrorsScreen(syncService: widget.syncService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }
}
