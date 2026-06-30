import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/order.dart';

class OrderCancelInput {
  const OrderCancelInput({
    required this.cancelledByName,
    required this.cancellationReason,
  });

  final String cancelledByName;
  final String cancellationReason;
}

Future<OrderCancelInput?> showOrderCancelDialog(
  BuildContext context, {
  required OrderItem order,
}) {
  return showDialog<OrderCancelInput>(
    context: context,
    builder: (ctx) => _OrderCancelDialog(order: order),
  );
}

class _OrderCancelDialog extends StatefulWidget {
  const _OrderCancelDialog({required this.order});

  final OrderItem order;

  @override
  State<_OrderCancelDialog> createState() => _OrderCancelDialogState();
}

class _OrderCancelDialogState extends State<_OrderCancelDialog> {
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      OrderCancelInput(
        cancelledByName: _nameController.text.trim(),
        cancellationReason: _reasonController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text('Siparişi İptal Et', style: AppTypography.titleLarge),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.order.orderNo} numaralı sipariş iptal edilecek.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'İptal Eden (Ad Soyad)',
                  hintText: 'Ad Soyad girin',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'İptal Nedeni',
                  hintText: 'İptal nedenini yazın',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'İptal nedeni zorunludur';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.critical,
          ),
          child: const Text('Siparişi İptal Et'),
        ),
      ],
    );
  }
}
