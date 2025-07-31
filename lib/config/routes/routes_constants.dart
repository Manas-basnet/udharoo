class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String transactionForm = '$transactions/transaction-form';
  static const String transactionDetail = '/transactions/transaction-detail';
  static const String pendingTransactions = '/transactions/pending-transactions';
  static const String completedTransactions = '/transactions/completed-transactions';
  static const String rejectedTransactions = '/transactions/rejected-transactions';
  static const String contacts = '/contacts';
  static const String contactTransactions = '$contacts/contact-transactions';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String profileCompletion = '/profile-completion';
  static const String phoneSetup = '/phone-setup';
  static const String phoneVerification = '/phone-verification';
  static const String changePhoneSetup = '/change-phone-setup';
  static const String changePhoneVerification = '/change-phone-verification';
  static const String qrScanner = '/qr-scanner';
  static const String qrGenerator = '/qr-generator';
 
  Routes._();
}