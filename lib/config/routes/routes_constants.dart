class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String contacts = '/contacts';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String profileCompletion = '/profile-completion';
  static const String phoneSetup = '/phone-setup';
  static const String phoneVerification = '/phone-verification';
  static const String changePhoneSetup = '/change-phone-setup';
  static const String changePhoneVerification = '/change-phone-verification';
  static const String transactionForm = '/transaction-form';
  static const String transactionDetail = '/transaction-detail';
  static const String qrScanner = '/qr-scanner';
  static const String qrGenerator = '/qr-generator';
  static const String finishedTransactions = '/finished-transactions';
  static const String contactTransactions = '/contact-transactions';
  static const String receivedTransactionRequests = '/received-transaction-requests';
  static const String completionRequests = '/completion-requests';

  static String transactionDetailGen(String transactionId) {
    return '/transaction-detail/$transactionId';
  }
  
  Routes._();
}