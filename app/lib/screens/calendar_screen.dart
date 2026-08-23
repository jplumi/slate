import 'package:flutter/material.dart';
import 'package:slate/widgets/calendar_panel.dart';
import '../app.dart';

class CalendarScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CalendarScreen({super.key, required this.selectedDate});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.ink,
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
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'sans-serif',
                ),
              ),
            ),
          ],
        ),
        body: CalendarPanel(
          selectedDate: _selectedDay,
          onDaySelected: (date) => Navigator.pop(context, date),
        ));
  }
}
