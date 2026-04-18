import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.statusCode});
}