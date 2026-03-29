import 'package:dartz/dartz.dart';
import 'package:dialer_app_poc/core/errors/failures.dart';
import 'package:dialer_app_poc/features/contacts/domain/entities/contact_entity.dart';

abstract class ContactRepository {
  Future<Either<Failure, List<ContactEntity>>> getContacts();
  Future<Either<Failure, void>> addContact(String firstName, String lastName, String phone);
  Future<Either<Failure, void>> updateContact(String id, String firstName, String lastName, String phone);
  Future<Either<Failure, void>> deleteContact(String id);
}
