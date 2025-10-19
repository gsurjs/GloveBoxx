import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense_category_data.dart';
import '../models/expense_monthly_data.dart';
import '../services/database_helper.dart';

class ExpenseSummaryScreen extends StatefulWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  late Future<Map<String, dynamic>> _expenseDataFuture;
  final List<Color> _categoryColors = [
    Colors.blue, Colors.green, Colors.orange, Colors.red,
    Colors.purple, Colors.teal, Colors.pink, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _expenseDataFuture = _fetchExpenseData();
  }

  // Fetch both sets of data at the same time
  Future<Map<String, dynamic>> _fetchExpenseData() async {
    final categoryData = await DatabaseHelper.instance.getExpensesByCategory();
    final monthlyData = await DatabaseHelper.instance.getExpensesByMonth();
    return {'categoryData': categoryData, 'monthlyData': monthlyData};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _expenseDataFuture = _fetchExpenseData();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _expenseDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No expense data to display.'));
          }

          final List<ExpenseCategoryData> categoryData = snapshot.data!['categoryData'];
          final List<ExpenseMonthlyData> monthlyData = snapshot.data!['monthlyData'];
          double totalSpent = categoryData.fold(0, (sum, item) => sum + item.totalCost);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Total Spent Card ---
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
              
              // --- Pie Chart Section ---
              if (categoryData.isNotEmpty) ...[
                const Text('Expenses by Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(categoryData.length, (i) {
                        final cat = categoryData[i];
                        final percentage = (cat.totalCost / totalSpent) * 100;
                        return PieChartSectionData(
                          color: _categoryColors[i % _categoryColors.length],
                          value: cat.totalCost,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(categoryData.length, (i) {
                  final cat = categoryData[i];
                  return ListTile(
                    leading: Icon(Icons.square, color: _categoryColors[i % _categoryColors.length]),
                    title: Text(cat.category),
                    trailing: Text(NumberFormat.currency(symbol: '\$').format(cat.totalCost)),
                  );
                }),
              ],
              
              const Divider(height: 40),

              // --- Line Chart Section ---
              if (monthlyData.isNotEmpty) ...[
                const Text('Monthly Trends', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: _bottomTitles(monthlyData)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(monthlyData.length, (i) {
                            return FlSpot(i.toDouble(), monthlyData[i].totalCost);
                          }),
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Helper method to create bottom titles for the line chart
  SideTitles _bottomTitles(List<ExpenseMonthlyData> monthlyData) {
    return SideTitles(
      showTitles: true,
      reservedSize: 30,
      getTitlesWidget: (value, meta) {
        final int index = value.toInt();
        if (index >= 0 && index < monthlyData.length) {
          // Format 'YYYY-MM' to 'MMM'
          final monthDate = DateTime.parse('${monthlyData[index].month}-01');
          final String monthLabel = DateFormat.MMM().format(monthDate);
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 8.0,
            child: Text(monthLabel, style: const TextStyle(fontSize: 12)),
          );
        }
        return const Text('');
      },
    );
  }
}