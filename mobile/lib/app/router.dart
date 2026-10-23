import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/route_paths.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/reports/presentation/reports_list_screen.dart';
import '../features/reports/presentation/create_report_screen.dart';
import '../features/reports/presentation/report_details_screen.dart';
import '../features/reports/presentation/report_confirmation_screen.dart';
import '../features/reports/presentation/drafts_screen.dart';
import '../features/reports/presentation/sync_queue_screen.dart';
import '../features/incidents/presentation/incidents_list_screen.dart';
import '../features/incidents/presentation/incident_details_screen.dart';
import '../features/tasks/presentation/tasks_list_screen.dart';
import '../features/tasks/presentation/task_details_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import 'app_shell.dart';
import 'splash_screen.dart';
import '../shared/screens/unauthorized_screen.dart';
import '../features/auth/data/auth_repository.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplash = state.matchedLocation == RoutePaths.splash;

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return RoutePaths.login;
      if (isLoggedIn && isAuthRoute) return RoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.reports,
            builder: (context, state) => const ReportsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CreateReportScreen(),
              ),
              GoRoute(
                path: 'drafts',
                builder: (context, state) => const DraftsScreen(),
              ),
              GoRoute(
                path: 'sync',
                builder: (context, state) => const SyncQueueScreen(),
              ),
              GoRoute(
                path: 'confirmation/:reportId',
                builder: (context, state) => ReportConfirmationScreen(
                  reportId: state.pathParameters['reportId']!,
                ),
              ),
              GoRoute(
                path: ':reportId',
                builder: (context, state) => ReportDetailsScreen(
                  reportId: state.pathParameters['reportId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.incidents,
            builder: (context, state) => const IncidentsListScreen(),
            routes: [
              GoRoute(
                path: ':incidentId',
                builder: (context, state) => IncidentDetailsScreen(
                  incidentId: state.pathParameters['incidentId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.tasks,
            builder: (context, state) => const TasksListScreen(),
            routes: [
              GoRoute(
                path: ':taskId',
                builder: (context, state) => TaskDetailsScreen(
                  taskId: state.pathParameters['taskId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.error}'),
      ),
    ),
  );
});
