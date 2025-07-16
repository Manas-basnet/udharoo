import 'package:flutter/material.dart';
import 'package:udharoo/shared/presentation/widgets/log_out_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutDialog.show(context),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Udharoo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your digital ledger for loans and borrows',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(Icons.trending_up),
                title: Text('Dashboard'),
                subtitle: Text('View your financial overview'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Manage Loans'),
                subtitle: Text('Track loans you have given'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Manage Borrows'),
                subtitle: Text('Track money you have borrowed'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('Transaction History'),
                subtitle: Text('View all past transactions'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('Contacts'),
                subtitle: Text('Manage your contacts'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
          ],
        ),
      ),
    );
  }
}