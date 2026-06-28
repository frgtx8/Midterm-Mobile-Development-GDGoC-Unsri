import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/transaction.dart';

/// Pie chart showing expense breakdown by category.
class ExpensePieChart extends StatelessWidget {
  final List<CategoryBreakdown> breakdown;

  const ExpensePieChart({super.key, required this.breakdown});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = breakdown.fold<double>(0, (sum, b) => sum + b.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: breakdown.map((b) {
                    final percentage = total > 0 ? (b.total / total * 100) : 0;
                    return PieChartSectionData(
                      value: b.total,
                      color: _parseColor(b.categoryColor),
                      radius: 40,
                      title: '${percentage.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            ...breakdown.map((b) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(b.categoryColor),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b.categoryName, style: Theme.of(context).textTheme.bodySmall)),
                  Text(
                    AppFormatters.compactCurrency(b.total),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
