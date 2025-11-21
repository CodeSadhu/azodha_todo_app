part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final String searchQuery;
  final bool showSyncedToast;

  TaskLoaded(this.tasks, {this.searchQuery = '', this.showSyncedToast = false});

  List<TaskModel> get filteredTasks {
    if (searchQuery.isEmpty) return tasks;
    return tasks
        .where(
          (task) =>
              task.title.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  TaskLoaded copyWith({
    List<TaskModel>? tasks,
    String? searchQuery,
    bool? showSyncedToast,
  }) {
    return TaskLoaded(
      tasks ?? this.tasks,
      searchQuery: searchQuery ?? this.searchQuery,
      showSyncedToast: showSyncedToast ?? false,
    );
  }

  @override
  List<Object?> get props => [tasks, searchQuery, showSyncedToast];
}

class TaskError extends TaskState {
  final String message;

  TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
