import 'package:hive/hive.dart';
import '../models/task_model.dart';

class TaskLocalDomain {
  static const String _boxName = 'tasks';

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<List<TaskModel>> getTasks() async {
    final box = await _getBox();
    return box.values
        .map((map) => TaskModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final box = await _getBox();
    await box.clear();
    for (var task in tasks) {
      await box.put(task.id, task.toJson());
    }
  }

  Future<void> cacheTask(TaskModel task) async {
    final box = await _getBox();
    await box.put(task.id, task.toJson());
  }

  Future<void> deleteTask(int id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> updateTask(TaskModel task) async {
    final box = await _getBox();
    await box.put(task.id, task.toJson());
  }
}
