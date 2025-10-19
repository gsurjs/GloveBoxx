import 'package:flutter/material.dart';

class ExpenseSummaryScreen extends StatelessWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
      ),
      body: const Center(
        child: Text('Expense charts will be shown here.'),
      ),
    );
  }
}