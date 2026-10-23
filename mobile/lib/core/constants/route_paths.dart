class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  static const String home = '/app/home';

  // Reports
  static const String reports = '/app/reports';
  static const String reportNew = '/app/reports/new';
  static const String reportDrafts = '/app/reports/drafts';
  static const String reportSync = '/app/reports/sync';
  static const String reportConfirmation = '/app/reports/confirmation/:reportId';
  static const String reportDetails = '/app/reports/:reportId';

  // Incidents
  static const String incidents = '/app/incidents';
  static const String incidentMap = '/app/incidents/map';
  static const String incidentDetails = '/app/incidents/:incidentId';

  // Tasks
  static const String tasks = '/app/tasks';
  static const String taskDetails = '/app/tasks/:taskId';

  // Other
  static const String notifications = '/app/notifications';
  static const String profile = '/app/profile';
  static const String settings = '/app/settings';
  static const String settingsLanguage = '/app/settings/language';
  static const String help = '/app/help';
  static const String unauthorized = '/unauthorized';

  // Helpers
  static String reportConfirmationFor(String id) =>
      '/app/reports/confirmation/$id';
  static String reportDetailsFor(String id) => '/app/reports/$id';
  static String incidentDetailsFor(String id) => '/app/incidents/$id';
  static String taskDetailsFor(String id) => '/app/tasks/$id';
}
