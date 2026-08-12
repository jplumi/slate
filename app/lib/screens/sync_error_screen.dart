import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app.dart';
import '../services/sync_service.dart';

class SyncErrorsScreen extends StatelessWidget {
  final SyncService syncService;

  const SyncErrorsScreen({super.key, required this.syncService});

  @override
  Widget build(BuildContext context) {
    final errors = syncService.errorLog.reversed.toList();

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.ink,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sync errors',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'sans-serif',
          ),
        ),
      ),
      body: errors.isEmpty
          ? const Center(
              child: Text(
                'No sync errors',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 16,
                  fontFamily: 'sans-serif',
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: errors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final entry = errors[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEE, MMM d · HH:mm:ss').format(entry.time),
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.message,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 14,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
