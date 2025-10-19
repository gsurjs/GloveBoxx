import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense_category_data.dart';
import '../services/database_helper.dart';

class ExpenseSummaryScreen extends StatefulWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  late Future<List<ExpenseCategoryData>> _expenseDataFuture;
  final List<Color> _categoryColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.red,
    Colors.purple, Colors.teal, Colors.pink, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _expenseDataFuture = DatabaseHelper.instance.getExpensesByCategory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
      ),
      body: FutureBuilder<List<ExpenseCategoryData>>(
        future: _expenseDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No expense data to display.'));
          }

          final expenseData = snapshot.data!;
          double totalSpent = expenseData.fold(0, (sum, item) => sum + item.totalCost);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Total Spent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(symbol: '\$').format(totalSpent),
                        style: TextStyle(fontSize: 28, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Expenses by Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(expenseData.length, (i) {
                      final categoryData = expenseData[i];
                      final percentage = (categoryData.totalCost / totalSpent) * 100;
                      return PieChartSectionData(
                        color: _categoryColors[i % _categoryColors.length],
                        value: categoryData.totalCost,
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Legend for the pie chart
              ...List.generate(expenseData.length, (i) {
                final categoryData = expenseData[i];
                return ListTile(
                  leading: Icon(Icons.square, color: _categoryColors[i % _categoryColors.length]),
                  title: Text(categoryData.category),
                  trailing: Text(NumberFormat.currency(symbol: '\$').format(categoryData.totalCost)),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}