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
                return DayScreen(date: date);
              },
            ),
          ),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                                horizontal: 8, vertical: 2),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateNum,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            monthYear,
                            style: const TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'sans-serif',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: _openAllTasks,
                    icon: const Icon(Icons.list_alt_rounded),
                    color: Colors.white,
                    iconSize: 26,
                    tooltip: 'All tasks',
                  ),
                  IconButton(
                    onPressed: _openCalendar,
                    icon: const Icon(Icons.calendar_month_rounded),
                    color: Colors.white,
                    iconSize: 24,
                    tooltip: 'Open calendar',
                  ),
                  if (!isToday)
                    GestureDetector(
                      onTap: () => _jumpToDate(DateTime.now()),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'sans-serif',
                        ),
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
}
