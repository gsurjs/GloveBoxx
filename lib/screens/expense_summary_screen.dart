import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/expense_monthly_data.dart';
import '../providers/vehicle_provider.dart';
import '../services/database_helper.dart';
import '../widgets/empty_state_message.dart';


class ExpenseSummaryScreen extends StatelessWidget {
  const ExpenseSummaryScreen({super.key});

  Future<void> _exportReport(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box!.localToGlobal(Offset.zero) & box.size;

    final allRecords = await DatabaseHelper.instance.getAllRecordsForReport();
    if (!context.mounted) return;
    if (allRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(['Date', 'Vehicle', 'Type', 'Cost', 'Mileage', 'Notes']);
    for (var record in allRecords) {
      final date = DateTime.parse(record['date']);
      rows.add([
        DateFormat.yMd().format(date),
        '${record['year']} ${record['make']} ${record['model']}',
        record['type'],
        record['cost'],
        record['mileage'],
        record['notes']
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/maintenance_report.csv';
    final file = File(path);
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Vehicle Maintenance Report',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chartElementsColor = isDarkMode ? Colors.white70 : Colors.black54;
    final List<Color> categoryColors = [
      Colors.blue, Colors.green, Colors.orange, Colors.red,
      Colors.purple, Colors.teal, Colors.pink, Colors.amber,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vehicleProvider.fetchAllData(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vehicleProvider.fetchAllData(),
        child: vehicleProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vehicleProvider.expenseByCategory.isEmpty
                ? Stack(
                    children: [
                      ListView(),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const EmptyStateMessage(
                              icon: Icons.monetization_on_outlined,
                              title: 'No Expense Data',
                              message: 'Add a maintenance record with a cost to see your expense summary here.',
                            ),
                            const SizedBox(height: 20),
                            Builder(
                              builder: (BuildContext context) {
                                return ElevatedButton.icon(
                                  icon: const Icon(Icons.share),
                                  label: const Text('Export Report'),
                                  onPressed: () => _exportReport(context),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _buildCharts(context, vehicleProvider, isDarkMode, chartElementsColor, categoryColors),
      ),
    );
  }

  ListView _buildCharts(BuildContext context, VehicleProvider vehicleProvider, bool isDarkMode, Color chartElementsColor, List<Color> categoryColors) {
    final categoryData = vehicleProvider.expenseByCategory;
    final monthlyData = vehicleProvider.expenseByMonth;
    final double totalSpent = categoryData.fold(0, (sum, item) => sum + item.totalCost);

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
                  style: TextStyle(
                    fontSize: 28,
                    color: isDarkMode ? Colors.blue.shade200 : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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
                    color: categoryColors[i % categoryColors.length],
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
              leading: Icon(Icons.square, color: categoryColors[i % categoryColors.length]),
              title: Text(cat.category),
              trailing: Text(NumberFormat.currency(symbol: '\$').format(cat.totalCost)),
            );
          }),
        ],
        const Divider(height: 40),
        if (monthlyData.isNotEmpty) ...[
          const Text('Monthly Trends', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: chartElementsColor.withOpacity(0.2), strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(color: chartElementsColor.withOpacity(0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: _bottomTitles(monthlyData, chartElementsColor)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (value, meta) => Text('\$${value.toInt()}', style: TextStyle(color: chartElementsColor, fontSize: 12), textAlign: TextAlign.left))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: chartElementsColor)),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(monthlyData.length, (i) {
                      return FlSpot(i.toDouble(), monthlyData[i].totalCost);
                    }),
                    isCurved: true,
                    color: isDarkMode ? Colors.blue.shade300 : Theme.of(context).primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: (isDarkMode ? Colors.blue.shade300 : Theme.of(context).primaryColor)
                          .withAlpha((255 * 0.3).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 30),
        Center(
          child: Builder(
            builder: (BuildContext context) {
              return ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Export Report'),
                onPressed: () => _exportReport(context),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  SideTitles _bottomTitles(List<ExpenseMonthlyData> monthlyData, Color textColor) {
    return SideTitles(
      showTitles: true,
      reservedSize: 30,
      interval: 1,
      getTitlesWidget: (value, meta) {
        final int index = value.toInt();
        if (index >= 0 && index < monthlyData.length) {
          final monthDate = DateTime.parse('${monthlyData[index].month}-01');
          final String monthLabel = DateFormat.MMM().format(monthDate);
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 8.0,
            child: Text(monthLabel, style: TextStyle(fontSize: 12, color: textColor)),
          );
        }
        return const Text('');
      },
    );
  }
}