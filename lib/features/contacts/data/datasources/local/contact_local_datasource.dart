import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udharoo/features/contacts/data/models/contact_model.dart';
import 'package:udharoo/features/transactions/data/models/transaction_model.dart';

abstract class ContactLocalDatasource {
  Future<void> saveContact(ContactModel contact);
  Future<List<ContactModel>> getContacts(String userId);
  Future<ContactModel?> getContactById(String contactId, String userId);
  Future<ContactModel?> getContactByUserId(String contactUserId, String userId);
  Future<void> deleteContact(String contactId, String userId);
  Future<void> clearContacts(String userId);
  Future<List<ContactModel>> searchContacts(String query, String userId);
  Future<void> saveContacts(List<ContactModel> contacts, String userId);
  Future<int> getContactTransactionCount(String contactUserId, String userId);
}

class ContactLocalDatasourceImpl implements ContactLocalDatasource {
  static const String _contactsKey = 'contacts_';
  static const String _lastSyncKey = 'contacts_last_sync_';
  static const String _transactionsKey = 'transactions_';

  @override
  Future<void> saveContact(ContactModel contact) async {
    final contacts = await getContacts(contact.userId);
    final existingIndex = contacts.indexWhere((c) => c.id == contact.id);
    
    if (existingIndex != -1) {
      contacts[existingIndex] = contact;
    } else {
      contacts.add(contact);
    }
    
    await _saveContactsList(contacts, contact.userId);
  }

  @override
  Future<List<ContactModel>> getContacts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList(_getContactsKey(userId)) ?? [];
    
    return contactsJson.map((contactJson) {
      final Map<String, dynamic> json = jsonDecode(contactJson);
      return ContactModel.fromJson(json);
    }).toList()
      ..sort((a, b) => b.lastInteractionAt.compareTo(a.lastInteractionAt));
  }

  @override
  Future<ContactModel?> getContactById(String contactId, String userId) async {
    final contacts = await getContacts(userId);
    try {
      return contacts.firstWhere((contact) => contact.id == contactId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ContactModel?> getContactByUserId(String contactUserId, String userId) async {
    final contacts = await getContacts(userId);
    try {
      return contacts.firstWhere((contact) => contact.contactUserId == contactUserId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteContact(String contactId, String userId) async {
    final contacts = await getContacts(userId);
    contacts.removeWhere((contact) => contact.id == contactId);
    await _saveContactsList(contacts, userId);
  }

  @override
  Future<void> clearContacts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getContactsKey(userId));
    await prefs.remove(_getLastSyncKey(userId));
  }

  @override
  Future<List<ContactModel>> searchContacts(String query, String userId) async {
    final contacts = await getContacts(userId);
    final lowercaseQuery = query.toLowerCase();
    
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(lowercaseQuery) ||
             contact.phoneNumber.contains(query);
    }).toList();
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts, String userId) async {
    await _saveContactsList(contacts, userId);
    await _updateLastSync(userId);
  }

  @override
  Future<int> getContactTransactionCount(String contactUserId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_getTransactionsKey(userId)) ?? [];
      
      if (transactionsJson.isEmpty) return 0;
      
      int count = 0;
      for (final transactionJson in transactionsJson) {
        try {
          final Map<String, dynamic> json = jsonDecode(transactionJson);
          final transaction = TransactionModel.fromJson(json);
          
          if (transaction.otherParty.uid == contactUserId) {
            count++;
          }
        } catch (e) {
          continue;
        }
      }
      
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _saveContactsList(List<ContactModel> contacts, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = contacts.map((contact) => jsonEncode(contact.toJson())).toList();
    await prefs.setStringList(_getContactsKey(userId), contactsJson);
  }

  Future<void> _updateLastSync(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getLastSyncKey(userId), DateTime.now().toIso8601String());
  }

  String _getContactsKey(String userId) => '$_contactsKey$userId';
  String _getLastSyncKey(String userId) => '$_lastSyncKey$userId';
  String _getTransactionsKey(String userId) => '$_transactionsKey$userId';
}