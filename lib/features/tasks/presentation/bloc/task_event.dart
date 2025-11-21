part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskLoadRequested extends TaskEvent {}

class TaskRefreshRequested extends TaskEvent {}

class TaskCreateRequested extends TaskEvent {
  final String title;

  TaskCreateRequested(this.title);

  @override
  List<Object?> get props => [title];
}

class TaskToggleCompleted extends TaskEvent {
  final TaskModel task;

  TaskToggleCompleted(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskDeleteRequested extends TaskEvent {
  final int taskId;

  TaskDeleteRequested(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TaskSearchQueryChanged extends TaskEvent {
  final String query;

  TaskSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class TaskResetSyncedToast extends TaskEvent {}
