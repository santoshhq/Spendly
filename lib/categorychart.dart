import 'package:flutter/material.dart';
import 'package:expense_tracker/models/model_expense.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryChart extends StatefulWidget {
  final List<Modelexpense> expenses;

  const CategoryChart({super.key, required this.expenses});

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  int? _touchedIndex;

  Map<Category, double> get groupedData {
    final Map<Category, double> data = {};
    for (final expense in widget.expenses) {
      data.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return data;
  }

  String formatcateAmount(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}C';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = groupedData;

    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(12),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "  Today Spending: ₹0.00",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "  Start adding expenses to see your chart here!",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 320,
                child: AspectRatio(
                  aspectRatio: 1.6,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: 100,
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      barGroups: List.generate(5, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: 10.0,
                              width: 12,
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final double total = data.values.fold(0.0, (a, b) => a + b);
    final double maxY = data.values.reduce((a, b) => a > b ? a : b) + 50;
    final double maxAmount = data.values.reduce((a, b) => a > b ? a : b);
    final highestCategories =
        data.entries
            .where((entry) => entry.value == maxAmount)
            .map((e) => e.key.name.substring(0, 3).toUpperCase())
            .toList();
    final highestDisplay =
        highestCategories.length == 1
            ? data.entries
                .firstWhere((e) => e.value == maxAmount)
                .key
                .name
                .toUpperCase()
            : highestCategories.join('/');

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "  Today Spending:${formatcateAmount(total.toDouble())}",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              "  Highest Spending: $highestDisplay",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 320,
              child: AspectRatio(
                aspectRatio: data.length > 5 ? 2 : 1.5,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        tooltipBorderRadius: BorderRadius.circular(21),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final category = data.keys.elementAt(groupIndex);
                          final amount = rod.toY;
                          return BarTooltipItem(
                            '${category.name.toUpperCase()}\n${formatcateAmount(amount.toDouble())}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: maxY / 6,
                          getTitlesWidget: (value, meta) {
                            String label;
                            if (value >= 10000000) {
                              label =
                                  "₹${(value / 10000000).toStringAsFixed(1)}Cr";
                            } else if (value >= 100000) {
                              label =
                                  "₹${(value / 100000).toStringAsFixed(1)}L";
                            } else if (value >= 1000) {
                              label = "₹${(value / 1000).toStringAsFixed(1)}K";
                            } else {
                              label = "₹${value.toInt()}";
                            }
                            return Text(
                              label,
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: maxY / 6,
                          getTitlesWidget: (value, meta) {
                            final percent = (value / maxAmount * 100).clamp(
                              0,
                              100,
                            );
                            return Text(
                              "${percent.toStringAsFixed(0)}%",
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: data.length > 6 ? 50 : 40,
                          getTitlesWidget: (value, meta) {
                            final category = data.keys.elementAt(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: data.length > 8 ? -0.5 : 0,
                                child: Text(
                                  category.name.substring(0, 3).toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: data.length > 8 ? 10 : 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: maxY / 6,
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (index) {
                      final category = data.keys.elementAt(index);
                      final amount = data[category]!;

                      return BarChartGroupData(
                        x: index,
                        barsSpace: 5,
                        barRods: [
                          BarChartRodData(
                            toY: amount,
                            gradient: _getCategoryGradient(category),
                            borderRadius: BorderRadius.circular(6),
                            width: data.length > 10 ? 8 : 14,
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                        showingTooltipIndicators:
                            _touchedIndex == index ? [0] : [],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCategoryGradient(Category category) {
    switch (category) {
      case Category.food:
        return const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB22222)],
        );
      case Category.entertainment:
        return const LinearGradient(
          colors: [Color(0xFF008B8B), Color(0xFF20B2AA)],
        );
      case Category.travel:
        return const LinearGradient(
          colors: [Color(0xFF004C99), Color(0xFF4682B4)],
        );
      case Category.work:
        return const LinearGradient(
          colors: [Color(0xFF556F44), Color(0xFF556F44)],
        );
      case Category.education:
        return const LinearGradient(
          colors: [Color(0xFFE67E22), Color(0xFFE67E22)],
        );
      case Category.housing:
        return const LinearGradient(
          colors: [Color(0xFF660066), Color(0xFF800080)],
        );
      case Category.bills:
        return const LinearGradient(
          colors: [Color(0xFF2F4F4F), Color(0xFF2F4F4F)],
        );
      case Category.health:
        return const LinearGradient(
          colors: [Color(0xFF228B22), Color(0xFF228B22)],
        );
      case Category.fitness:
        return const LinearGradient(
          colors: [Color(0xFF00CED1), Color(0xFF00CED1)],
        );
      case Category.investment:
        return const LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF00B894)],
        );
      case Category.shopping:
        return const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFFBA55D3)],
        );
      case Category.subscriptions:
        return const LinearGradient(
          colors: [Color(0xFF6D2600), Color(0xFF8B4513)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFFF428D), Color(0xFFFF428D)],
        );
    }
  }
}
