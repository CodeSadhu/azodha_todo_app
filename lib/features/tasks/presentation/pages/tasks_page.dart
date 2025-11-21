import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/constants/strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_task_dialog.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(TaskLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskLoaded && state.showSyncedToast) {
          Fluttertoast.showToast(
            msg: "Synced",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          // Reset the toast flag
          context.read<TaskBloc>().add(TaskResetSyncedToast());
        }
      },
      child: Scaffold(
        appBar: _appBar(),
        body: Column(
          children: [
            _searchBar(),
            Expanded(child: _taskList()),
          ],
        ),
        floatingActionButton: _addButton(),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text(AppStrings.tasks),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppStrings.searchTasks,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (query) =>
            context.read<TaskBloc>().add(TaskSearchQueryChanged(query)),
      ),
    );
  }

  Widget _taskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TaskError) {
          return Center(child: Text(state.message));
        }

        if (state is TaskLoaded) {
          final tasks = state.filteredTasks;

          if (tasks.isEmpty) {
            return const Center(child: Text(AppStrings.noTasks));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TaskBloc>().add(TaskRefreshRequested());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskListItem(task: tasks[index]);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _addButton() {
    return FloatingActionButton(
      onPressed: () => _showAddTaskDialog(),
      child: const Icon(Icons.add),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<TaskBloc>(),
        child: const AddTaskDialog(),
      ),
    );
  }
}
