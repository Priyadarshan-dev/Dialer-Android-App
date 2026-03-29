class ContactEntity {
  final String id;
  final String displayName;
  final List<String> phoneNumbers;
  final String? photoUrl;
  final String? notes;

  ContactEntity({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    this.photoUrl,
    this.notes,
  });
}
