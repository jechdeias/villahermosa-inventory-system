import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/payments_provider.dart';
import '../services/payments_service.dart';
import 'payment_status_badge.dart';
import '../../../core/theme/app_theme.dart';

class PaymentDetailPanel extends ConsumerStatefulWidget {
  const PaymentDetailPanel({super.key, required this.payment});
  final Payment payment;

  @override
  ConsumerState<PaymentDetailPanel> createState() => _PaymentDetailPanelState();
}

class _PaymentDetailPanelState extends ConsumerState<PaymentDetailPanel> {
  final _amountCtrl = TextEditingController();
  String? _selectedMethod;
  bool _saving = false;

  static const _methods = ['Cash', 'GCash', 'Bank', 'Check'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0 || _selectedMethod == null) return;
    setState(() => _saving = true);
    try {
      await PaymentsService.instance.recordPayment(
        paymentId: widget.payment.id,
        amount: amount,
        method: _selectedMethod!,
      );
      if (mounted) {
        ref.read(selectedPaymentProvider.notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    final canRecord = p.status != 'paid';
    final progress = p.orderAmount > 0 ? (p.amountPaid / p.orderAmount).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panelHeader(context, p),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('ORDER INFO', [
                  _infoRow('Order',    p.orderCode, mono: true),
                  _infoRow('Store',    p.storeName),
                  _infoRow('Sales Rep', p.salesRepName),
                  _infoRow('Date',     _fmtDate(p.paymentDate)),
                ]),
                const SizedBox(height: 16),
                _section('PAYMENT SUMMARY', [
                  _infoRow('Order Amount', '₱${_fmt(p.orderAmount)}', bold: true),
                  _infoRow('Amount Paid',  '₱${_fmt(p.amountPaid)}',
                      color: AppTheme.success, bold: true),
                  _infoRow('Balance',
                      '₱${_fmt(p.balance)}',
                      color: p.balance > 0 ? AppTheme.error : AppTheme.textMuted,
                      bold: p.balance > 0),
                  _infoRow('Status', '', widget: PaymentStatusBadge(status: p.status)),
                  _infoRow('Method', p.paymentMethod ?? '—'),
                ]),
                const SizedBox(height: 12),
                _progressBar(progress, pct),
                if (canRecord) ...[
                  const SizedBox(height: 16),
                  _section('RECORD NEW PAYMENT', []),
                  const SizedBox(height: 8),
                  const Text('Amount', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 34,
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter amount...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textLight),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(color: Color(0xFF374151)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Payment method', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  _methodToggle(),
                ],
              ],
            ),
          ),
        ),
        _panelFooter(context, canRecord),
      ],
    );
  }

  Widget _panelHeader(BuildContext context, Payment p) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Payment — ${p.orderCode}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(selectedPaymentProvider.notifier).state = null,
              child: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
            ),
          ],
        ),
      );

  Widget _panelFooter(BuildContext context, bool canRecord) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ref.read(selectedPaymentProvider.notifier).state = null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border),
                  foregroundColor: const Color(0xFF374151),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 13)),
              ),
            ),
            if (canRecord) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _recordPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Record Payment', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _section(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...rows,
        ],
      );

  Widget _infoRow(String label, String value,
      {bool mono = false, bool bold = false, Color? color, Widget? widget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: widget ??
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                    color: color ?? AppTheme.textPrimary,
                    fontFamily: mono ? AppTheme.monoFamily : null,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double progress, String pct) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Payment progress',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const Spacer(),
              Text('$pct%',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
            ),
          ),
        ],
      );

  Widget _methodToggle() => Wrap(
        spacing: 6,
        children: _methods.map((m) {
          final selected = _selectedMethod == m;
          return GestureDetector(
            onTap: () => setState(() => _selectedMethod = m),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                m,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppTheme.textMuted),
              ),
            ),
          );
        }).toList(),
      );

  static String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
