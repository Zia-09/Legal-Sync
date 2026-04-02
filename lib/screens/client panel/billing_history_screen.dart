import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legal_sync/provider/client_provider.dart';
import 'package:legal_sync/provider/billing_provider.dart';
import 'package:legal_sync/provider/invoice_provider.dart';
import 'package:intl/intl.dart';

class BillingHistoryScreen extends ConsumerStatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  ConsumerState<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends ConsumerState<BillingHistoryScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FC);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF9E9E9E) : Colors.grey.shade600;

    final clientAsync = ref.watch(currentClientProvider);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 16),
            ),
          ),
        ),
        title: Text(
          'Billing History',
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.download_outlined, color: textColor),
          ),
        ],
      ),
      body: clientAsync.when(
        data: (client) {
          if (client == null) return const Center(child: Text('User not found'));
          
          final billingAsync = ref.watch(streamBillingByClientProvider(client.clientId));
          final invoicesAsync = ref.watch(streamInvoicesByClientProvider(client.clientId));
          
          return invoicesAsync.when(
            data: (invoices) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  billingAsync.when(
                    data: (billing) => _buildSummaryCard(billing, cardColor, textColor, subtitleColor, isDark),
                    loading: () => _buildSummaryCardSkeleton(cardColor, isDark),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                  _buildFilters(isDark),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Invoices',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInvoicesList(invoices, cardColor, textColor, subtitleColor, isDark),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626))),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626))),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSummaryCard(dynamic billing, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
    final paidAmount = billing?.paidAmount ?? 0.0;
    final totalAmount = billing?.totalAmount ?? 0.0;
    final percentage = totalAmount > 0 ? (paidAmount / totalAmount) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Case Fee Summary', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAID TO DATE', style: TextStyle(color: subtitleColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text('Rs. ${NumberFormat("#,##0").format(paidAmount)}', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ESTIMATED TOTAL', style: TextStyle(color: subtitleColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Text('Rs. ${NumberFormat("#,##0").format(totalAmount)}', style: TextStyle(color: subtitleColor, fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Color(0xFFDC2626), size: 16),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toInt()}% of estimated case total settled',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    final filters = ['All', 'Paid', 'Pending', 'Overdue'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFDC2626) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : Theme.of(context).dividerColor),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInvoicesList(List invoices, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
    if (invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_outlined, color: subtitleColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'No invoices yet',
                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: invoices
          .where((inv) {
            if (_selectedFilter == 'All') return true;
            return inv.status.toUpperCase() == _selectedFilter.toUpperCase();
          })
          .map((invoice) => _buildInvoiceItem(
                invoice.description ?? 'Invoice',
                invoice.invoiceId,
                invoice.totalAmount ?? 0.0,
                DateFormat('MMM dd, yyyy').format(invoice.createdDate),
                invoice.status ?? 'DRAFT',
                _getStatusColor(invoice.status ?? 'DRAFT'),
                cardColor,
                textColor,
                subtitleColor,
                isDark,
              ))
          .toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'OVERDUE':
        return Colors.red;
      case 'DRAFT':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildSummaryCardSkeleton(Color cardColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Case Fee Summary', style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PAID TO DATE', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 20, color: Colors.grey.shade300),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ESTIMATED TOTAL', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 20, color: Colors.grey.shade300),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(String title, String invNo, double amount, String date, String status, Color statusColor, Color cardColor, Color textColor, Color subtitleColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice #$invNo', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(title, style: TextStyle(color: subtitleColor, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AMOUNT', style: TextStyle(color: subtitleColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('Rs. ${NumberFormat("#,##0").format(amount)}', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(status == 'OVERDUE' ? 'PAST DUE' : (status == 'PENDING' ? 'DUE DATE' : 'DATE'), 
                      style: TextStyle(color: subtitleColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(color: status == 'OVERDUE' ? Colors.red : textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
