import 'package:flutter/material.dart';
import '../../data/models/income_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/theme/app_theme.dart';

/// Card widget for displaying income in a list
class IncomeCard extends StatelessWidget {
  final IncomeModel income;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Source icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSourceIcon(income.source),
                  color: AppTheme.incomeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Income details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              income.source,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (income.category != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              income.category!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          app_date_utils.DateUtils.formatRelative(income.date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount and delete button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(income.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.incomeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red[300],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    final lowerSource = source.toLowerCase();

    if (lowerSource.contains('salary')) return Icons.work;
    if (lowerSource.contains('freelance')) return Icons.laptop;
    if (lowerSource.contains('business')) return Icons.business;
    if (lowerSource.contains('investment')) return Icons.trending_up;
    if (lowerSource.contains('gift')) return Icons.card_giftcard;

    return Icons.account_balance_wallet;
  }
}
