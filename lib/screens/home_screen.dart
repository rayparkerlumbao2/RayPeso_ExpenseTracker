import 'package:material_ui/material_ui.dart';

import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_form_sheet.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/peso_ray_logo.dart';

class HomeScreen extends StatelessWidget {
  final ExpenseProvider provider;

  const HomeScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            PesoRayLogo(size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'PesoRay',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Firestore Sync Button / Status
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: provider.isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    provider.isCloudSyncActive
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_queue_rounded,
                    color: provider.isCloudSyncActive
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
            tooltip: provider.isCloudSyncActive
                ? 'Sync with Firestore (Connected)'
                : 'Sync with Firestore',
            onPressed: () async {
              final success = await provider.syncWithFirestore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Synced with Firestore successfully'
                          : 'Cloud sync is inactive or failed',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          // Currency picker button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(20)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                provider.currencySymbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            tooltip: 'Change Currency',
            onPressed: () => _showCurrencyDialog(context),
          ),
          // Theme mode toggle
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(
              provider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : (provider.themeMode == ThemeMode.light
                      ? Icons.dark_mode_rounded
                      : Icons.brightness_auto_rounded),
              size: 20,
            ),
            tooltip: 'Toggle Theme',
            onPressed: provider.toggleTheme,
          ),
          // More options menu
          PopupMenuButton<String>(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: 'More options',
            onSelected: (value) async {
              if (value == 'sync_firestore') {
                final success = await provider.syncWithFirestore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Synced with Firestore'
                            : 'Sync could not complete',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Expenses?'),
                    content: const Text(
                      'This will permanently delete all expenses stored locally and in Cloud Firestore.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.clearAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All data cleared'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sync_firestore',
                child: Row(
                  children: [
                    Icon(Icons.cloud_sync_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Sync with Firestore'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await provider.setSelectedMonth(provider.selectedMonth);
                if (provider.isCloudSyncActive) {
                  await provider.syncWithFirestore();
                }
              },
              child: CustomScrollView(
                slivers: [
                  // Month navigation bar
                  SliverToBoxAdapter(
                    child: MonthSelectorBar(provider: provider),
                  ),

                  // Prominent Monthly Total & Summary Card
                  SliverToBoxAdapter(
                    child: MonthlySummaryCard(provider: provider),
                  ),

                  // Category Breakdown Pie Chart
                  SliverToBoxAdapter(
                    child: CategoryPieChart(provider: provider),
                  ),

                  // Expense List Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Expenses',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withAlpha(15)
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${provider.transactionCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (provider.expenses.isNotEmpty)
                            Text(
                              'Swipe to delete',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Chronological Expense List grouped by date
                  if (provider.expenses.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(provider: provider),
                    )
                  else
                    ..._buildGroupedExpenseList(context),

                  // Padding at bottom for FAB clearance
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => ExpenseFormSheet(provider: provider),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedExpenseList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final groups = provider.groupedExpensesByDay;
    final sortedDays = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final List<Widget> slivers = [];

    for (final day in sortedDays) {
      final dayExpenses = groups[day]!;
      final dayTotal = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);

      // Day Header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppFormatters.formatRelativeDate(day),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(
                    dayTotal,
                    currencySymbol: provider.currencySymbol,
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // List of expenses for this day
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, index) {
              final expense = dayExpenses[index];
              return ExpenseListItem(
                expense: expense,
                provider: provider,
              );
            },
            childCount: dayExpenses.length,
          ),
        ),
      );
    }

    return slivers;
  }

  void _showCurrencyDialog(BuildContext context) {
    final currencies = [
      {'symbol': '₱', 'name': 'PHP / Philippine Peso (₱)'},
      {'symbol': '\$', 'name': 'USD / US Dollar (\$)'},
      {'symbol': '€', 'name': 'EUR / Euro (€)'},
      {'symbol': '£', 'name': 'GBP / British Pound (£)'},
      {'symbol': '¥', 'name': 'JPY/CNY / Yen (¥)'},
      {'symbol': '₹', 'name': 'INR / Rupee (₹)'},
      {'symbol': 'C\$', 'name': 'CAD / Canadian Dollar (C\$)'},
      {'symbol': 'A\$', 'name': 'AUD / Australian Dollar (A\$)'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Currency Symbol'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final item = currencies[index];
              final isSelected = provider.currencySymbol == item['symbol'];
              return ListTile(
                leading: Text(
                  item['symbol']!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(item['name']!),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  provider.setCurrency(item['symbol']!);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
