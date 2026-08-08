import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:todo_app/models/task.dart';
import 'api_client.dart';
import 'task_storage.dart';

class SyncService extends ChangeNotifier {
  final ApiClient _api;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;
  Timer? _debounceTimer;

  bool get isSyncing => _syncing;

  String? _lastError;
  String? get lastError => _lastError;

  void clearError() {
    _lastError = null;
  }

  final StreamController<void> _syncController =
      StreamController<void>.broadcast();
  Stream<void> get onSyncComplete => _syncController.stream;

  SyncService(this._api);

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncNow();
      }
    });
    syncNow();
  }

  void scheduleSync({Duration delay = const Duration(milliseconds: 1200)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, syncNow);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _syncController.close();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    notifyListeners();
    try {
      // 1. Push local dirty tasks (creates/edits/deletes)
      final dirty = await TaskStorage.getUnsyncedTasks();
      for (final task in dirty) {
        if (task.isDeleted) {
          await _api.deleteTask(task);
        } else {
          await _api.saveTask(task);
        }
        await TaskStorage.markSynced(task.id);
      }

      // 2. Pull remote changes since last sync
      List<Task> remoteChanges;

      final lastSync = await TaskStorage.getLastSyncTime();
      if (lastSync == null) {
        remoteChanges = await _api.getAll();
      } else {
        remoteChanges = await _api.getChangesSince(lastSync);
      }

      for (final remoteTask in remoteChanges) {
        if (remoteTask.isDeleted) {
          TaskStorage.hardDeleteTask(remoteTask.id);
        } else {
          await TaskStorage.mergeRemoteTask(remoteTask);
        }
      }

      await TaskStorage.setLastSyncTime(DateTime.now());
      _syncController.add(null);
    } catch (e, st) {
      print("syncNow failed: $e");
      print(st);
      _lastError = e.toString();
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }
}
