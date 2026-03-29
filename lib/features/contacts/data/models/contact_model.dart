import 'package:hive/hive.dart';
import '../../domain/entities/contact_entity.dart';

part 'contact_model.g.dart';

@HiveType(typeId: 1)
class ContactModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String displayName;
  
  @HiveField(2)
  final List<String> phoneNumbers;
  
  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final String? notes;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    this.photoUrl,
    this.notes,
  });

  ContactEntity toEntity() {
    return ContactEntity(
      id: id,
      displayName: displayName,
      phoneNumbers: phoneNumbers,
      photoUrl: photoUrl,
      notes: notes,
    );
  }
}
