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
class AppNetworkException extends AppException {
  const AppNetworkException([
    super.message = 'Network connection failed',
    String? code,
  ]) : super(code: code);
}

/// Authentication/Session errors.
class AppAuthException extends AppException {
  const AppAuthException([
    super.message = 'Authentication failed',
    String? code,
  ]) : super(code: code);
}

/// Data validation errors.
class AppValidationException extends AppException {
  const AppValidationException(super.message, {super.code});
}

/// Storage & Database access errors.
class AppStorageException extends AppException {
  const AppStorageException([
    super.message = 'Storage access failed',
    String? code,
  ]) : super(code: code);
}
