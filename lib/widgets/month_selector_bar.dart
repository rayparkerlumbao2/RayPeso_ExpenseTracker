import 'package:material_ui/material_ui.dart';

import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

class MonthSelectorBar extends StatelessWidget {
  final ExpenseProvider provider;

  const MonthSelectorBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: provider.previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous month',
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withAlpha(12)
                  : theme.colorScheme.surfaceContainerHighest.withAlpha(160),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showMonthPickerSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(180),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : theme.colorScheme.outlineVariant.withAlpha(100),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatMonthYear(provider.selectedMonth),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!provider.isCurrentMonth) ...[
                TextButton(
                  onPressed: provider.goToCurrentMonth,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Today'),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                onPressed: provider.nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next month',
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withAlpha(12)
                      : theme.colorScheme.surfaceContainerHighest.withAlpha(
                          160,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthPickerSheet(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    // List of last 12 months + next 2 months for quick selection
    final months = <DateTime>[];
    for (int i = -11; i <= 2; i++) {
      months.add(DateTime(now.year, now.month + i, 1));
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      final m = months[index];
                      final isSelected =
                          m.year == provider.selectedMonth.year &&
                          m.month == provider.selectedMonth.month;
                      final isThisMonth =
                          m.year == now.year && m.month == now.month;

                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          AppFormatters.formatMonthYear(m),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: isThisMonth
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          provider.setSelectedMonth(m);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
