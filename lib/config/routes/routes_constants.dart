class Routes {
  static const String home = '/home';
  static const String signUp = '/sign-up';
  static const String login = '/login';
  
  static const String transactions = '/transactions';
  static const String lentTransactions = '/transactions/lent';
  static const String borrowedTransactions = '/transactions/borrowed';
  static const String transactionForm = '/transactions/transaction-form';
  static const String rejectedTransactions = '/transactions/rejected-transactions';
  static const String transactionDetail = '/transactions/transaction-detail';
  
  static const String contacts = '/contacts';
  static const String contactTransactions = '/contacts/contact-transactions';
  static const String contactLentTransactions = '/contacts/contact-transactions/lent';
  static const String contactBorrowedTransactions = '/contacts/contact-transactions/borrowed';
  
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  
  static const String qrGenerator = '/qr-generator';
  static const String qrScanner = '/qr-scanner';
  
  static const String profileCompletion = '/profile-completion';
  static const String phoneVerification = '/phone-verification';
  static const String phoneSetup = '/phone-setup';
  static const String changePhoneSetup = '/change-phone-setup';
  static const String changePhoneVerification = '/change-phone-verification';

  // Helper functions for routes with parameters
  static String contactTransactionsF(String contactUserId) => 
      '/contacts/contact-transactions?contactUserId=$contactUserId';
  
  static String contactLentTransactionsF(String contactUserId) => 
      '/contacts/contact-transactions/lent?contactUserId=$contactUserId';
  
  static String contactBorrowedTransactionsF(String contactUserId) => 
      '/contacts/contact-transactions/borrowed?contactUserId=$contactUserId';
}