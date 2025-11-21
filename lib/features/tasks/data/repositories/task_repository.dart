import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/task_local_domain.dart';
import '../domain/task_remote_domain.dart';
import '../models/task_model.dart';

class TaskRepository {
  final TaskRemoteDomain _remoteDomain;
  final TaskLocalDomain _localDomain;
  final Connectivity _connectivity;

  TaskRepository(this._remoteDomain, this._localDomain, this._connectivity);

  Future<bool> _isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
  }

  Future<List<TaskModel>> getTasksFromLocal() async {
    return await _localDomain.getTasks();
  }

  Future<List<TaskModel>> refreshTasksFromServer() async {
    if (!await _isConnected()) {
      return await _localDomain.getTasks();
    }

    try {
      final remoteTasks = await _remoteDomain.getTasks();
      final localTasks = await _localDomain.getTasks();

      // Keep only user-created tasks (IDs > 1000000000 are timestamps)
      final userCreatedTasks = localTasks
          .where((t) => t.id > 1000000000)
          .toList();

      // Merge: user tasks first, then server tasks
      final mergedTasks = <TaskModel>[...userCreatedTasks, ...remoteTasks];

      await _localDomain.cacheTasks(mergedTasks);
      return mergedTasks;
    } catch (_) {
      return await _localDomain.getTasks();
    }
  }

  Future<TaskModel> createTask(TaskModel task) async {
    await _localDomain.cacheTask(task);
    return task;
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    await _localDomain.updateTask(task);
    return task;
  }

  Future<void> deleteTask(int id) async {
    await _localDomain.deleteTask(id);
  }

  Future<bool> syncCreateToServer(TaskModel task) async {
    if (!await _isConnected()) return false;

    // Skip sync for user-created tasks (they don't exist on server)
    if (task.id > 1000000000) {
      return true; // Return true to indicate "successful" skip
    }

    try {
      await _remoteDomain.createTask(task);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncUpdateToServer(TaskModel task) async {
    if (!await _isConnected()) return false;

    // Skip sync for user-created tasks (they don't exist on server)
    if (task.id > 1000000000) {
      return true; // Return true to indicate "successful" skip
    }

    try {
      await _remoteDomain.updateTask(task);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> syncDeleteToServer(int id) async {
    if (!await _isConnected()) return false;

    // Skip sync for user-created tasks (they don't exist on server)
    if (id > 1000000000) {
      return true; // Return true to indicate "successful" skip
    }

    try {
      await _remoteDomain.deleteTask(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
