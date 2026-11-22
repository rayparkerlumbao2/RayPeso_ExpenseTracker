import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

class CategoryPieChart extends StatelessWidget {
  final ExpenseProvider provider;

  const CategoryPieChart({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = provider.monthlyTotal;
    final categoryTotals = provider.sortedCategoryTotals;

    if (total == 0 || categoryTotals.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E222D)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(20)
                : theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses for this month',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add an expense to view category distribution',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final touchedIndex = provider.touchedChartIndex;
    final touchedEntry =
        (touchedIndex != null &&
            touchedIndex >= 0 &&
            touchedIndex < categoryTotals.length)
        ? categoryTotals[touchedIndex]
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E222D)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Breakdown',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${categoryTotals.length} Categories',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          provider.setTouchedChartIndex(null);
                          return;
                        }
                        provider.setTouchedChartIndex(
                          pieTouchResponse.touchedSection!.touchedSectionIndex,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 58,
                    sections: List.generate(categoryTotals.length, (i) {
                      final entry = categoryTotals[i];
                      final isTouched = i == touchedIndex;
                      final radius = isTouched ? 42.0 : 34.0;
                      final pct = (entry.value / total) * 100;

                      return PieChartSectionData(
                        color: entry.key.color,
                        value: entry.value,
                        title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                        radius: radius,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                // Center text showing touched info or total
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (touchedEntry != null) ...[
                      Icon(
                        touchedEntry.key.icon,
                        size: 20,
                        color: touchedEntry.key.color,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        touchedEntry.key.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: touchedEntry.key.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppFormatters.formatCurrency(
                          touchedEntry.value,
                          currencySymbol: provider.currencySymbol,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${((touchedEntry.value / total) * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(
                          total,
                          currencySymbol: provider.currencySymbol,
                          decimalDigits: 0,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Category breakdown list
          Column(
            children: List.generate(categoryTotals.length, (i) {
              final entry = categoryTotals[i];
              final isTouched = i == touchedIndex;
              final pct = entry.value / total;

              return InkWell(
                onTap: () {
                  provider.setTouchedChartIndex(isTouched ? null : i);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isTouched
                        ? entry.key.color.withAlpha(25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: entry.key.color.withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entry.key.icon,
                          size: 16,
                          color: entry.key.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isTouched
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(
                                    entry.value,
                                    currencySymbol: provider.currencySymbol,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 5,
                                      backgroundColor: isDark
                                          ? Colors.white.withAlpha(20)
                                          : Colors.black.withAlpha(15),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        entry.key.color,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 44,
                                  child: Text(
                                    AppFormatters.formatPercentage(pct),
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
