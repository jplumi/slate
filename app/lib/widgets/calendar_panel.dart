import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../app.dart';
import '../services/task_storage.dart';

class CalendarPanel extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDaySelected;

  const CalendarPanel({
    super.key,
    required this.selectedDate,
    required this.onDaySelected,
  });

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  late DateTime _focusedDay;
  Set<String> _datesWithTasks = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _loadDatesWithTasks();
  }

  @override
  void didUpdateWidget(covariant CalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _focusedDay = widget.selectedDate;
    }
  }

  Future<void> _loadDatesWithTasks() async {
    final dates = await TaskStorage.getAllDatesWithTasks();
    if (mounted) setState(() => _datesWithTasks = dates);
  }

  bool _hasTasksOnDay(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _datesWithTasks.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2035, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(widget.selectedDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        final normalized =
            DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
        setState(() => _focusedDay = focusedDay);
        widget.onDaySelected(normalized);
        _loadDatesWithTasks();
      },
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle:
            const TextStyle(color: Colors.white, fontFamily: 'sans-serif'),
        weekendTextStyle:
            const TextStyle(color: Colors.white, fontFamily: 'sans-serif'),
        selectedDecoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        selectedTextStyle: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w700,
            fontFamily: 'sans-serif'),
        todayDecoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle),
        todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'sans-serif'),
        markerDecoration: const BoxDecoration(
            color: AppTheme.accentRed, shape: BoxShape.circle),
        markersMaxCount: 1,
        markerSize: 5,
        markerMargin: const EdgeInsets.only(top: 2),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'sans-serif'),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'sans-serif'),
        weekendStyle: TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'sans-serif'),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (_hasTasksOnDay(day) && !isSameDay(day, widget.selectedDate)) {
            return Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isSameDay(day, DateTime.now())
                      ? Colors.white
                      : AppTheme.accentRed.withValues(alpha: 0.7),
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
