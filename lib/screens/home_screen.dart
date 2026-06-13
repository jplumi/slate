import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import 'calendar_screen.dart';
import 'day_screen.dart';
import 'all_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index 10000 = today. Allows ~27 years in each direction.
  static const int _todayIndex = 10000;
  static const int _totalPages = 20000;

  final Map<int, GlobalKey<State<StatefulWidget>>> _dayKeys = {};

  late final PageController _pageController;
  late DateTime _currentDate;
  int _currentIndex = _todayIndex;

  @override
  void initState() {
    super.initState();
    _currentDate = _dateFromIndex(_todayIndex);
    _pageController = PageController(initialPage: _todayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  GlobalKey<State<StatefulWidget>> _keyForIndex(int index) {
    return _dayKeys.putIfAbsent(
        index, () => GlobalKey<State<StatefulWidget>>());
  }

  DateTime _dateFromIndex(int index) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return base.add(Duration(days: index - _todayIndex));
  }

  int _indexFromDate(DateTime date) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return _todayIndex + date.difference(base).inDays;
  }

  void _jumpToDate(DateTime date) {
    final index = _indexFromDate(date);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _openCalendar() async {
    final selected = await Navigator.push<DateTime>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CalendarScreen(selectedDate: _currentDate),
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
    if (selected != null) {
      _jumpToDate(selected);
    }
  }

  void _openAllTasks() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AllTasksScreen(),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _currentDate = _dateFromIndex(index);
                });
              },
              itemBuilder: (context, index) {
                final date = _dateFromIndex(index);
                return DayScreen(key: _keyForIndex(index), date: date);
              },
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isToday = _isToday(_currentDate);
    final dayName = DateFormat('EEEE').format(_currentDate).toUpperCase();
    final dateNum = DateFormat('d').format(_currentDate);
    final monthYear = DateFormat('MMMM yyyy').format(_currentDate);

    return Container(
      color: AppTheme.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    dateNum,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'sans-serif',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: AppTheme.ink,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBarIcon(Icons.calendar_today_rounded, 'Today', () {
                _jumpToDate(DateTime.now());
              }),
              _buildBarIcon(Icons.list_alt_rounded, 'All tasks', _openAllTasks),
              GestureDetector(
                onTap: _openAddTask,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
              _buildBarIcon(
                  Icons.calendar_month_rounded, 'Calendar', _openCalendar),
              _buildBarIcon(Icons.settings_outlined, 'Settings', () {
                // placeholder for future settings screen
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.55), size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: Color(0x8DFFFFFF),
                fontSize: 9,
                fontFamily: 'sans-serif',
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTask() {
    final key = _keyForIndex(_currentIndex);
    final state = key.currentState as dynamic;
    state?.showAddSheet();
  }
}
