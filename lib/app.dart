import 'package:azodha_todo/features/tasks/presentation/pages/tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/constants/strings.dart';
import 'core/constants/api_constants.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/tasks/data/domain/task_local_domain.dart';
import 'features/tasks/data/domain/task_remote_domain.dart';
import 'features/tasks/data/repositories/task_repository.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
      ),
    );

    final connectivity = Connectivity();

    final taskRepository = TaskRepository(
      TaskRemoteDomain(dio),
      TaskLocalDomain(),
      connectivity,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(AuthRepository(const FlutterSecureStorage()))
                ..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => TaskBloc(taskRepository, connectivity),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is AuthAuthenticated) {
              return const TasksPage();
            }

            return const LoginPage();
          },
        ),
      ),
    );
  }
}
