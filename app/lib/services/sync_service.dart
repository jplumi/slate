import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:todo_app/models/task.dart';
import 'api_client.dart'; // thin wrapper around your Go backend's REST endpoints
import 'task_storage.dart';

class SyncService {
  final ApiClient _api;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  SyncService(this._api);

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncNow();
      }
    });
    syncNow();
  }

  void dispose() => _sub?.cancel();

  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      // 1. Push local dirty tasks (creates/edits/deletes)
      final dirty = await TaskStorage.getUnsyncedTasks();
      print("==== unsynced: ");
      for (final task in dirty) {
        print("\t${task.title} - ${task.updatedAt}");
        if (task.isDeleted) {
          await _api.deleteTask(task.id);
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
        await TaskStorage.mergeRemoteTask(remoteTask);
      }

      await TaskStorage.setLastSyncTime(DateTime.now());
    } catch (e, st) {
      print("syncNow failed: $e");
      print(st);
    } finally {
      _syncing = false;
    }
  }
}
