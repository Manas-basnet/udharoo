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
  static const String lentTransactions = '/transactions/lent';
  static const String borrowedTransactions = '/transactions/borrowed';
  static const String contactTransactions = '$contacts/contact-transactions';
  static const String contacts = '/contacts';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String profileCompletion = '/profile-completion';
  static const String phoneSetup = '/phone-setup';
  static const String phoneVerification = '/phone-verification';
  static const String changePhoneSetup = '/change-phone-setup';
  static const String changePhoneVerification = '/change-phone-verification';
  static const String qrScanner = '/qr-scanner';
  static const String qrGenerator = '/qr-generator';

  static String contactTransactionsF(String contactUserId) => '${Routes.contactTransactions}?contactUserId=$contactUserId';
  static String contactLentTransactionsF(String contactUserId) => '${Routes.contactTransactions}/lent?contactUserId=$contactUserId';
  static String contactBorrowedTransactionsF(String contactUserId) => '${Routes.contactTransactions}/borrowed?contactUserId=$contactUserId';
 
  Routes._();
}