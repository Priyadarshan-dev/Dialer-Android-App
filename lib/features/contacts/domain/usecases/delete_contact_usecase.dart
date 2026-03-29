import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/repositories/contact_repository.dart';

class DeleteContactUseCase implements UseCase<void, String> {
  final ContactRepository repository;

  DeleteContactUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteContact(id);
  }
}
