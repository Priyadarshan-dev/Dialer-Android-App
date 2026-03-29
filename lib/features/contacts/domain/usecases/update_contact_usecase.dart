import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/repositories/contact_repository.dart';

class UpdateContactParams {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;

  UpdateContactParams({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });
}

class UpdateContactUseCase implements UseCase<void, UpdateContactParams> {
  final ContactRepository repository;

  UpdateContactUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateContactParams params) async {
    return await repository.updateContact(
      params.id,
      params.firstName,
      params.lastName,
      params.phone,
    );
  }
}
