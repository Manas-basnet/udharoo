import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/transactions/data/models/contact_history_model.dart';

abstract class ContactHistoryLocalDatasource {
  Future<void> saveContact(ContactHistoryModel contact);
  Future<List<ContactHistoryModel>> getContacts({int? limit, String? userId});
  Future<List<ContactHistoryModel>> searchContacts({
    required String query,
    int? limit,
    String? userId,
  });
  Future<void> deleteContact(String phoneNumber, String? userId);
  Future<void> clearContacts(String? userId);
  Future<ContactHistoryModel?> getContact(String phoneNumber, String? userId);
}

class ContactHistoryLocalDatasourceImpl implements ContactHistoryLocalDatasource {
  static const String _contactsListKey = 'contact_history_list';
  static const String _contactKeyPrefix = 'contact_history_';

  @override
  Future<void> saveContact(ContactHistoryModel contact) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save individual contact
    final contactKey = _getContactKey(contact.phoneNumber, contact.userId);
    final existingContactJson = prefs.getString(contactKey);
    
    ContactHistoryModel finalContact;
    if (existingContactJson != null) {
      // Update existing contact
      final existingContact = ContactHistoryModel.fromJson(
        jsonDecode(existingContactJson) as Map<String, dynamic>,
      );
      finalContact = existingContact.incrementUsage();
      
      // Update name if different
      if (existingContact.name != contact.name && contact.name.trim().isNotEmpty) {
        finalContact = finalContact.updateName(contact.name);
      }
    } else {
      finalContact = contact;
    }
    
    await prefs.setString(contactKey, jsonEncode(finalContact.toJson()));
    
    // Update contacts list
    await _updateContactsList(contact.userId, contact.phoneNumber);
  }

  @override
  Future<List<ContactHistoryModel>> getContacts({
    int? limit,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final listKey = _getContactsListKey(userId);
    final contactsListJson = prefs.getStringList(listKey) ?? [];
    
    final contacts = <ContactHistoryModel>[];
    
    for (final phoneNumber in contactsListJson) {
      final contactKey = _getContactKey(phoneNumber, userId);
      final contactJson = prefs.getString(contactKey);
      
      if (contactJson != null) {
        try {
          final contact = ContactHistoryModel.fromJson(
            jsonDecode(contactJson) as Map<String, dynamic>,
          );
          contacts.add(contact);
        } catch (e) {
          // Skip invalid contact data
          continue;
        }
      }
    }
    
    // Sort by last used (most recent first)
    contacts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    
    // Apply limit if specified
    if (limit != null && limit < contacts.length) {
      return contacts.take(limit).toList();
    }
    
    return contacts;
  }

  @override
  Future<List<ContactHistoryModel>> searchContacts({
    required String query,
    int? limit,
    String? userId,
  }) async {
    final allContacts = await getContacts(userId: userId);
    final lowercaseQuery = query.toLowerCase();
    
    final filteredContacts = allContacts.where((contact) {
      return contact.name.toLowerCase().contains(lowercaseQuery) ||
             contact.phoneNumber.contains(query);
    }).toList();
    
    // Apply limit if specified
    if (limit != null && limit < filteredContacts.length) {
      return filteredContacts.take(limit).toList();
    }
    
    return filteredContacts;
  }

  @override
  Future<void> deleteContact(String phoneNumber, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove from individual storage
    final contactKey = _getContactKey(phoneNumber, userId);
    await prefs.remove(contactKey);
    
    // Remove from contacts list
    final listKey = _getContactsListKey(userId);
    final contactsList = prefs.getStringList(listKey) ?? [];
    contactsList.remove(phoneNumber);
    await prefs.setStringList(listKey, contactsList);
  }

  @override
  Future<void> clearContacts(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get all contacts for this user
    final contacts = await getContacts(userId: userId);
    
    // Remove individual contact entries
    for (final contact in contacts) {
      final contactKey = _getContactKey(contact.phoneNumber, userId);
      await prefs.remove(contactKey);
    }
    
    // Clear contacts list
    final listKey = _getContactsListKey(userId);
    await prefs.remove(listKey);
  }

  @override
  Future<ContactHistoryModel?> getContact(String phoneNumber, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final contactKey = _getContactKey(phoneNumber, userId);
    final contactJson = prefs.getString(contactKey);
    
    if (contactJson != null) {
      try {
        return ContactHistoryModel.fromJson(
          jsonDecode(contactJson) as Map<String, dynamic>,
        );
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  String _getContactKey(String phoneNumber, String? userId) {
    final userPrefix = userId != null ? '${userId}_' : '';
    return '$_contactKeyPrefix$userPrefix$phoneNumber';
  }

  String _getContactsListKey(String? userId) {
    final userPrefix = userId != null ? '${userId}_' : '';
    return '$userPrefix$_contactsListKey';
  }

  Future<void> _updateContactsList(String? userId, String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final listKey = _getContactsListKey(userId);
    final contactsList = prefs.getStringList(listKey) ?? [];
    
    // Remove if exists (to re-add at beginning)
    contactsList.remove(phoneNumber);
    
    // Add at beginning (most recent)
    contactsList.insert(0, phoneNumber);
    
    // Keep only last 50 contacts to prevent unlimited growth
    if (contactsList.length > 50) {
      final removedContacts = contactsList.sublist(50);
      for (final removed in removedContacts) {
        final contactKey = _getContactKey(removed, userId);
        await prefs.remove(contactKey);
      }
      contactsList.removeRange(50, contactsList.length);
    }
    
    await prefs.setStringList(listKey, contactsList);
  }
}