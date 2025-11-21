import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/task_model.dart';

class TaskRemoteDomain {
  final Dio _dio;

  TaskRemoteDomain(this._dio);

  Future<List<TaskModel>> getTasks() async {
    final response = await _dio.get(ApiConstants.todos);
    final List<dynamic> data = response.data;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  Future<TaskModel> createTask(TaskModel task) async {
    final response = await _dio.post(ApiConstants.todos, data: task.toJson());
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> updateTask(TaskModel task) async {
    final response = await _dio.patch(
      '${ApiConstants.todos}/${task.id}',
      data: {'completed': task.completed},
    );
    return TaskModel.fromJson(response.data);
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete('${ApiConstants.todos}/$id');
  }
}
