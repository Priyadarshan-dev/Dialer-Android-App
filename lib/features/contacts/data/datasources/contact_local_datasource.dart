import 'package:hive/hive.dart';
import 'package:dialer_app_poc/features/contacts/data/models/contact_model.dart';
import 'package:dialer_app_poc/core/services/shared_preferences_service.dart';
import 'package:uuid/uuid.dart';

abstract class ContactLocalDataSource {
  Future<List<ContactModel>> getContacts();
  Future<void> addContact(String firstName, String lastName, String phone);
}

class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  final Box<ContactModel> box;

  ContactLocalDataSourceImpl(this.box);

  @override
  Future<List<ContactModel>> getContacts() async {
    print('[DEBUG] ContactLocalDataSource: Fetching CRM contacts from Hive...');
    return box.values.toList();
  }

  @override
  Future<void> addContact(String firstName, String lastName, String phone) async {
    print('[DEBUG] ContactLocalDataSource: Adding new CRM contact to Hive...');
    
    final id = const Uuid().v4();
    final displayName = '$firstName $lastName'.trim();
    
    final newContact = ContactModel(
      id: id,
      displayName: displayName,
      phoneNumbers: [phone],
    );
    
    // 1. Save to CRM Internal DB (Hive)
    await box.put(id, newContact);
    
    // 2. Sync to SharedPreferences so Native Overlay can see the NAME
    // We reuse SharedPreferencesService which is already used for syncing notes.
    // This ensures that when this number calls, the name "$firstName $lastName" appears.
    await SharedPreferencesService.saveNoteToSharedPrefs(
      phone, 
      '', // No initial notes, just syncing the name
      contactName: displayName
    );
    
    print('[DEBUG] ContactLocalDataSource: CRM Contact successfully added and synced for Caller ID.');
  }
}

