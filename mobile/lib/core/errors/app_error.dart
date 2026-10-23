sealed class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  final int? statusCode;
  const NetworkError(super.message, {this.statusCode});
}

class AuthError extends AppError {
  const AuthError(super.message);
}

class ValidationError extends AppError {
  final Map<String, String> fieldErrors;
  const ValidationError(super.message, {this.fieldErrors = const {}});
}

class NotFoundError extends AppError {
  const NotFoundError(super.message);
}

class PermissionError extends AppError {
  const PermissionError(super.message);
}

class StorageError extends AppError {
  const StorageError(super.message);
}

class UnknownError extends AppError {
  final Object? cause;
  const UnknownError(super.message, {this.cause});
}
