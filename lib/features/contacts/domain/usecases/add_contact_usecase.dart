import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/repositories/contact_repository.dart';

class AddContactParams {
  final String firstName;
  final String lastName;
  final String phone;
  final String? notes;

  AddContactParams({required this.firstName, required this.lastName, required this.phone, this.notes});
}

class AddContactUseCase implements UseCase<void, AddContactParams> {
  final ContactRepository repository;

  AddContactUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddContactParams params) async {
    return await repository.addContact(params.firstName, params.lastName, params.phone, notes: params.notes);
  }
}
