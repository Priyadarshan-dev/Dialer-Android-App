import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/core/usecases/usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/usecases/get_contacts_usecase.dart';
import 'package:dialer_app_poc/features/contacts/domain/usecases/add_contact_usecase.dart';
import 'package:dialer_app_poc/features/contacts/presentation/states/contacts_state.dart';
import 'package:dialer_app_poc/core/services/shared_preferences_service.dart';

class ContactsNotifier extends StateNotifier<ContactsState> {
  final GetContactsUseCase _getContactsUseCase;
  final AddContactUseCase _addContactUseCase;

  ContactsNotifier(this._getContactsUseCase, this._addContactUseCase) : super(ContactsState());

  Future<void> loadContacts() async {
    print('[DEBUG] ContactsNotifier: Starting loadContacts...');
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getContactsUseCase(NoParams());
    
    result.fold(
      (failure) {
        print('[DEBUG] ContactsNotifier: Load failed with failure: $failure');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (contacts) {
        print('[DEBUG] ContactsNotifier: Load successful. Found ${contacts.length} contacts.');
        state = state.copyWith(
          isLoading: false,
          contacts: contacts,
          filtered: contacts,
        );
        // Sync to SharedPreferences for background service matching
        SharedPreferencesService.syncAllContactsToSharedPrefs(contacts);
      },
    );
  }

  void searchContacts(String query) {
    print('[DEBUG] ContactsNotifier: Searching for query: "$query"');
    if (query.isEmpty) {
      state = state.copyWith(filtered: state.contacts, searchQuery: query);
    } else {
      final filtered = state.contacts.where((c) {
        return c.displayName.toLowerCase().contains(query.toLowerCase()) ||
               c.phoneNumbers.any((p) => p.contains(query));
      }).toList();
      print('[DEBUG] ContactsNotifier: Filtered to ${filtered.length} matches');
      state = state.copyWith(filtered: filtered, searchQuery: query);
    }
  }

  Future<void> addContact(String firstName, String lastName, String phone) async {
    print('[DEBUG] ContactsNotifier: Adding contact...');
    final result = await _addContactUseCase(AddContactParams(firstName: firstName, lastName: lastName, phone: phone));
    
    result.fold(
      (failure) {
        print('[DEBUG] ContactsNotifier: Add contact failed: ${failure}');
        state = state.copyWith(error: failure.message);
      },
      (_) {
        print('[DEBUG] ContactsNotifier: Contact added successfully, reloading list...');
        loadContacts();
      },
    );
  }
}
