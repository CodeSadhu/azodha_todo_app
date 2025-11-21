import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/strings.dart';
import '../bloc/task_bloc.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.addTask),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: AppStrings.taskTitle,
            hintText: AppStrings.enterTaskTitle,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.taskTitleEmpty;
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _onCreatePressed,
          child: const Text(AppStrings.create),
        ),
      ],
    );
  }

  void _onCreatePressed() {
    if (_formKey.currentState!.validate()) {
      context.read<TaskBloc>().add(
        TaskCreateRequested(_controller.text.trim()),
      );
      Navigator.pop(context);
    }
  }
}
