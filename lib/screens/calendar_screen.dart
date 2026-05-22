import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app.dart';
import '../services/task_storage.dart';

class CalendarScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CalendarScreen({super.key, required this.selectedDate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Set<String> _datesWithTasks = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _selectedDay = widget.selectedDate;
    _loadDatesWithTasks();
  }

  Future<void> _loadDatesWithTasks() async {
    final dates = await TaskStorage.getAllDatesWithTasks();
    setState(() => _datesWithTasks = dates);
  }

  bool _hasTasksOnDay(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _datesWithTasks.contains(key);
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
          title: const Text(
            'Calendar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'sans-serif',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, DateTime.now());
              },
              child: const Text(
                'Today',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ],
        ),
        body: _buildCalendar());
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        final normalized = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );
        Navigator.pop(context, normalized);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: const TextStyle(
          color: AppTheme.ink,
          fontFamily: 'sans-serif',
        ),
        weekendTextStyle: const TextStyle(
          color: AppTheme.ink,
          fontFamily: 'sans-serif',
        ),
        selectedDecoration: const BoxDecoration(
          color: AppTheme.accent,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFamily: 'sans-serif',
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.ink.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: AppTheme.ink,
          fontWeight: FontWeight.w700,
          fontFamily: 'sans-serif',
        ),
        markerDecoration: const BoxDecoration(
          color: AppTheme.accent,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 1,
        markerSize: 5,
        markerMargin: const EdgeInsets.only(top: 2),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          color: AppTheme.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'sans-serif',
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.ink),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.ink),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'sans-serif',
        ),
        weekendStyle: TextStyle(
          color: AppTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'sans-serif',
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (_hasTasksOnDay(day) && !isSameDay(day, _selectedDay)) {
            return Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSameDay(day, DateTime.now())
                      ? AppTheme.ink
                      : AppTheme.accent.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
