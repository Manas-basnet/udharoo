import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:udharoo/features/contacts/data/models/contact_model.dart';

abstract class ContactRemoteDatasource {
  Future<void> saveContact(ContactModel contact);
  Future<List<ContactModel>> getContacts(String userId);
  Future<ContactModel?> getContactById(String contactId, String userId);
  Future<ContactModel?> getContactByUserId(String contactUserId, String userId);
  Future<void> deleteContact(String contactId, String userId);
}

class ContactRemoteDatasourceImpl implements ContactRemoteDatasource {
  final FirebaseFirestore _firestore;

  ContactRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _getUserContactsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('contacts');
  }

  @override
  Future<void> saveContact(ContactModel contact) async {
    await _getUserContactsCollection(contact.userId)
        .doc(contact.id)
        .set(contact.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<ContactModel>> getContacts(String userId) async {
    final snapshot = await _getUserContactsCollection(userId)
        .orderBy('lastInteractionAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return ContactModel.fromJson(doc.data());
    }).toList();
  }

  @override
  Future<ContactModel?> getContactById(String contactId, String userId) async {
    final doc = await _getUserContactsCollection(userId).doc(contactId).get();
    
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    
    return ContactModel.fromJson(doc.data()!);
  }

  @override
  Future<ContactModel?> getContactByUserId(String contactUserId, String userId) async {
    final snapshot = await _getUserContactsCollection(userId)
        .where('contactUserId', isEqualTo: contactUserId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return ContactModel.fromJson(snapshot.docs.first.data());
  }

  @override
  Future<void> deleteContact(String contactId, String userId) async {
    await _getUserContactsCollection(userId).doc(contactId).delete();
  }
}