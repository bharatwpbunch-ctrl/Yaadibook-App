/// Base domain exception for Yaadibook.
sealed class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Network-related errors.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network connection failed',
    String? code,
  ]) : super(code: code);
}

/// Authentication/Session errors.
class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed', String? code])
    : super(code: code);
}

/// Data validation errors.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Local storage errors.
class StorageException extends AppException {
  const StorageException([
    super.message = 'Storage access failed',
    String? code,
  ]) : super(code: code);
}
