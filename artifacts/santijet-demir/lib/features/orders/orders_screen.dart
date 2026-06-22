import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/orders/providers/orders_provider.dart';
import 'package:santijet_demir/features/orders/widgets/order_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(filteredOrdersProvider);
    final filterIndex = ref.watch(orderFilterProvider);

    final filtered = _searchQuery.isEmpty
        ? orders
        : orders
            .where(
              (o) =>
                  o.orderNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  o.supplier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  o.imalatTypes.any(
                    (t) => t.toLowerCase().contains(_searchQuery.toLowerCase()),
                  ),
            )
            .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SantijetHeader(subtitle: 'SİPARİŞLER'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: AppSearchBar(
                hint: 'Sipariş no, firma, imalat ara...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: FilterChips(
                labels: orderFilterLabels,
                selectedIndex: filterIndex,
                onSelected: (i) =>
                    ref.read(orderFilterProvider.notifier).state = i,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? ModuleEmptyState(
                      type: EmptyStateType.noSearchResult,
                      actionLabel: 'Yeni Sipariş',
                      onAction: () => context.push(AppRoutes.newOrder),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return OrderCard(order: filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFab(
        label: 'Yeni Sipariş',
        onPressed: () => context.push(AppRoutes.newOrder),
      ),
    );
  }
}
