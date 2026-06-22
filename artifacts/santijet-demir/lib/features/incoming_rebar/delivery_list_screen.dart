import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/data/mock/mock_deliveries.dart';
import 'package:santijet_demir/features/incoming_rebar/providers/incoming_rebar_provider.dart';
import 'package:santijet_demir/features/incoming_rebar/widgets/delivery_card.dart';

class DeliveryListScreen extends ConsumerStatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  ConsumerState<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends ConsumerState<DeliveryListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final deliveries = ref.watch(filteredDeliveriesProvider);
    final filterIndex = ref.watch(deliveryFilterProvider);

    final filtered = _searchQuery.isEmpty
        ? deliveries
        : deliveries.where((d) {
            final q = _searchQuery.toLowerCase();
            return d.orderNo.toLowerCase().contains(q) ||
                d.supplier.toLowerCase().contains(q) ||
                d.irsaliyeNo.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Teslimat Listesi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppSearchBar(
              hint: 'Sipariş no, firma, irsaliye ara...',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: FilterChips(
              labels: deliveryFilterLabels,
              selectedIndex: filterIndex,
              onSelected: (i) =>
                  ref.read(deliveryFilterProvider.notifier).state = i,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final delivery = filtered[index];
                return DeliveryCard(
                  delivery: delivery,
                  onTap: () => context.push(AppRoutes.deliveryDetail(delivery.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
