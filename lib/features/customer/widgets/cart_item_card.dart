import 'package:flutter/material.dart';
import '../providers/customer_providers.dart';
import 'customer_common.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.item, required this.onQtyChanged, required this.onRemove});
  final CartItem item;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: CcColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CcColors.text)),
                  const SizedBox(height: 4),
                  Text('${formatPeso(item.product.unitPrice)} × ${item.quantity}', style: const TextStyle(fontSize: 12, color: CcColors.muted)),
                ]),
              ),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 22, color: CcColors.muted, semanticLabel: 'Remove')),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              CcQtyStepper(value: item.quantity, onChanged: onQtyChanged),
              const Spacer(),
              Text(formatPeso(item.subtotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CcColors.text)),
            ]),
          ],
        ),
      );
}
