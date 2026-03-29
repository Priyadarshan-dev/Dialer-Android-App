import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dialer_app_poc/providers.dart';
import 'package:dialer_app_poc/features/contacts/domain/entities/contact_entity.dart';

class AddContactDialog extends ConsumerStatefulWidget {
  final ContactEntity? contact;
  final String? initialPhone;

  const AddContactDialog({
    super.key, 
    this.contact,
    this.initialPhone,
  });

  @override
  ConsumerState<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends ConsumerState<AddContactDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    
    String firstName = '';
    String lastName = '';
    String phone = widget.initialPhone ?? '';

    if (widget.contact != null) {
      final names = widget.contact!.displayName.split(' ');
      firstName = names.isNotEmpty ? names[0] : '';
      lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
      phone = widget.contact!.phoneNumbers.isNotEmpty 
          ? widget.contact!.phoneNumbers.first 
          : '';
    }

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveContact() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty || phone.isEmpty) {
      return;
    }

    final notifier = ref.read(contactsProvider.notifier);
    
    if (widget.contact != null) {
      // Edit Mode
      notifier.updateContact(widget.contact!.id, firstName, lastName, phone);
    } else {
      // Add Mode
      notifier.addContact(firstName, lastName, phone);
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1C1C1E),
      surfaceTintColor: Colors.transparent,
      title: Text(
        isEdit ? 'Edit Contact' : 'New Contact',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(label: 'First Name', controller: _firstNameController, keyboardType: TextInputType.name),
            const SizedBox(height: 16),
            _buildTextField(label: 'Last Name', controller: _lastNameController, keyboardType: TextInputType.name),
            const SizedBox(height: 16),
            _buildTextField(label: 'Phone Number', controller: _phoneController, keyboardType: TextInputType.phone),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(isEdit ? 'Update' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, required TextInputType keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
