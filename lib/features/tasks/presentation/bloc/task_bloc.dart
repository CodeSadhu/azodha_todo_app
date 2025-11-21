import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository _taskRepository;
  final Connectivity _connectivity;
  Timer? _toastDebounceTimer;
  final Map<String, int> _syncRetryCount = {};
  final Map<String, Timer> _syncRetryTimers = {};

  TaskBloc(this._taskRepository, this._connectivity) : super(TaskInitial()) {
    on<TaskLoadRequested>(_onTaskLoadRequested);
    on<TaskRefreshRequested>(_onTaskRefreshRequested);
    on<TaskCreateRequested>(_onTaskCreateRequested);
    on<TaskToggleCompleted>(_onTaskToggleCompleted);
    on<TaskDeleteRequested>(_onTaskDeleteRequested);
    on<TaskSearchQueryChanged>(_onTaskSearchQueryChanged);
    on<TaskResetSyncedToast>(_onTaskResetSyncedToast);
  }

  @override
  Future<void> close() {
    _toastDebounceTimer?.cancel();
    for (var timer in _syncRetryTimers.values) {
      timer.cancel();
    }
    return super.close();
  }

  bool _isServerTask(int id) {
    // Server tasks have IDs 1-200, user tasks have timestamp IDs
    return id <= 200;
  }

  Future<void> _onTaskLoadRequested(
    TaskLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    try {
      final tasks = await _taskRepository.getTasksFromLocal();

      if (tasks.isEmpty) {
        final refreshedTasks = await _taskRepository.refreshTasksFromServer();
        emit(TaskLoaded(refreshedTasks));
      } else {
        emit(TaskLoaded(tasks));
      }
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onTaskRefreshRequested(
    TaskRefreshRequested event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final tasks = await _taskRepository.refreshTasksFromServer();
      if (state is TaskLoaded) {
        emit(TaskLoaded(tasks, searchQuery: (state as TaskLoaded).searchQuery));
      } else {
        emit(TaskLoaded(tasks));
      }
    } catch (e) {
      if (state is TaskLoaded) {
        // Keep existing state if refresh fails
      } else {
        emit(TaskError(e.toString()));
      }
    }
  }

  Future<void> _onTaskCreateRequested(
    TaskCreateRequested event,
    Emitter<TaskState> emit,
  ) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;

      // Generate a positive ID using timestamp (last 8 digits to stay within range)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final positiveId = timestamp % 0xFFFFFFFF;

      final newTask = TaskModel(
        id: positiveId,
        userId: 1,
        title: event.title,
        completed: false,
      );

      final updatedTasks = [newTask, ...currentState.tasks];

      emit(currentState.copyWith(tasks: updatedTasks));

      await _taskRepository.createTask(newTask);
    }
  }

  Future<void> _onTaskToggleCompleted(
    TaskToggleCompleted event,
    Emitter<TaskState> emit,
  ) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final updatedTask = event.task.copyWith(completed: !event.task.completed);

      final updatedTasks = currentState.tasks
          .map((task) => task.id == updatedTask.id ? updatedTask : task)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));

      await _taskRepository.updateTask(updatedTask);

      // Only sync server tasks
      if (_isServerTask(updatedTask.id)) {
        _syncToServer(
          'update_${updatedTask.id}',
          () => _taskRepository.syncUpdateToServer(updatedTask),
          emit,
        );
      }
    }
  }

  Future<void> _onTaskDeleteRequested(
    TaskDeleteRequested event,
    Emitter<TaskState> emit,
  ) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final updatedTasks = currentState.tasks
          .where((task) => task.id != event.taskId)
          .toList();

      emit(currentState.copyWith(tasks: updatedTasks));

      await _taskRepository.deleteTask(event.taskId);

      // Only sync server tasks
      if (_isServerTask(event.taskId)) {
        _syncToServer(
          'delete_${event.taskId}',
          () => _taskRepository.syncDeleteToServer(event.taskId),
          emit,
        );
      }
    }
  }

  void _onTaskSearchQueryChanged(
    TaskSearchQueryChanged event,
    Emitter<TaskState> emit,
  ) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      emit(TaskLoaded(currentState.tasks, searchQuery: event.query));
    }
  }

  void _onTaskResetSyncedToast(
    TaskResetSyncedToast event,
    Emitter<TaskState> emit,
  ) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      emit(currentState.copyWith(showSyncedToast: false));
    }
  }

  void _syncToServer(
    String operationKey,
    Future<bool> Function() syncOperation,
    Emitter<TaskState> emit,
  ) {
    _syncRetryCount[operationKey] = 0;
    _attemptSync(operationKey, syncOperation, emit);
  }

  void _attemptSync(
    String operationKey,
    Future<bool> Function() syncOperation,
    Emitter<TaskState> emit,
  ) async {
    print('🔄 Attempting sync for: $operationKey');
    try {
      final success = await syncOperation();
      print('✅ Sync result for $operationKey: $success');

      if (success) {
        _syncRetryCount.remove(operationKey);
        _syncRetryTimers[operationKey]?.cancel();
        _syncRetryTimers.remove(operationKey);

        print('📊 Remaining syncs: ${_syncRetryCount.length}');

        // Emit toast state when all syncs are complete (debounced)
        if (_syncRetryCount.isEmpty && state is TaskLoaded && !emit.isDone) {
          print('🎉 All syncs complete, scheduling toast state');

          // Cancel existing timer if any
          _toastDebounceTimer?.cancel();

          // Debounce - only emit after 500ms of no new sync completions
          _toastDebounceTimer = Timer(const Duration(milliseconds: 500), () {
            if (_syncRetryCount.isEmpty &&
                state is TaskLoaded &&
                !emit.isDone) {
              print('🍞 Emitting synced toast state');
              final currentState = state as TaskLoaded;
              emit(currentState.copyWith(showSyncedToast: true));
            }
          });
        }
      } else {
        print('❌ Sync failed for $operationKey');
        _handleSyncFailure(operationKey, syncOperation, emit);
      }
    } catch (e) {
      print('💥 Sync exception for $operationKey: $e');
      _handleSyncFailure(operationKey, syncOperation, emit);
    }
  }

  void _handleSyncFailure(
    String operationKey,
    Future<bool> Function() syncOperation,
    Emitter<TaskState> emit,
  ) {
    final retryCount = _syncRetryCount[operationKey] ?? 0;

    if (retryCount < 3) {
      _syncRetryCount[operationKey] = retryCount + 1;

      _syncRetryTimers[operationKey]?.cancel();
      _syncRetryTimers[operationKey] = Timer(const Duration(seconds: 3), () {
        _attemptSync(operationKey, syncOperation, emit);
      });
    } else {
      // Max retries reached, remove from tracking
      _syncRetryCount.remove(operationKey);
      _syncRetryTimers[operationKey]?.cancel();
      _syncRetryTimers.remove(operationKey);
    }
  }
}
