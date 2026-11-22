import 'package:material_ui/material_ui.dart';

import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

class MonthlySummaryCard extends StatelessWidget {
  final ExpenseProvider provider;

  const MonthlySummaryCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = provider.monthlyTotal;
    final topCategory = provider.topSpendingCategory;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2638), const Color(0xFF161B26)]
              : [
                  theme.colorScheme.primaryContainer.withAlpha(200),
                  theme.colorScheme.surfaceContainerHighest.withAlpha(240),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(25)
              : theme.colorScheme.outlineVariant.withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'MONTHLY SPENDING',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(15)
                      : theme.colorScheme.surface.withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppFormatters.formatMonthYear(provider.selectedMonth),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.formatCurrency(
                total,
                currencySymbol: provider.currencySymbol,
              ),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withAlpha(40)
                  : theme.colorScheme.surface.withAlpha(150),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  context,
                  label: 'Transactions',
                  value: '${provider.transactionCount}',
                  icon: Icons.receipt_long_rounded,
                ),
                _buildDivider(isDark),
                _buildMetric(
                  context,
                  label: 'Daily Avg',
                  value: AppFormatters.formatCurrency(
                    provider.dailyAverage,
                    currencySymbol: provider.currencySymbol,
                    decimalDigits: 0,
                  ),
                  icon: Icons.timeline_rounded,
                ),
                _buildDivider(isDark),
                _buildMetric(
                  context,
                  label: 'Top Category',
                  value: topCategory != null
                      ? topCategory.name.split(' ').first
                      : '-',
                  icon: topCategory?.icon ?? Icons.category_rounded,
                  iconColor: topCategory?.color,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 26,
      width: 1,
      color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20),
    );
  }
}
