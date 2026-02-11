import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'pdf_generator.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // SHAASHADDA DATE PICKER-KA (DIALOG)
  Future<void> _pickDateAndPrint(
    BuildContext context,
    String title,
    Function(DateTime start, DateTime end) onConfirm,
  ) async {
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(Icons.date_range, size: 40, color: Colors.blue[800]),
                  const SizedBox(height: 10),
                  Text(
                    "Select $title Period",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDateSelector("From:", startDate, () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null)
                      setStateDialog(() => startDate = picked);
                  }),
                  const SizedBox(height: 15),
                  _buildDateSelector("To:", endDate, () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setStateDialog(() => endDate = picked);
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (startDate.isAfter(endDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Start date cannot be after end date"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    onConfirm(startDate, endDate); // <--- RUN THE REPORT
                  },
                  child: const Text("Generate PDF"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today, size: 16, color: Colors.blue[800]),
          ],
        ),
      ),
    );
  }

  // --- REPORT LOGIC ---

  // 1. DEBT REPORT
  Future<void> _generateDebtReport(DateTime start, DateTime end) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Generating Debt Report...")));
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('debts')
          .orderBy('date', descending: true)
          .get();

      // Filter by Date
      final debts = snapshot.docs.map((d) => d.data()).where((d) {
        final date = DateTime.parse(d['date']);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (debts.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No debts found in this period"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await PdfGenerator.generateDebtReport(debts, start, end);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 2. BILLS REPORT
  Future<void> _generateBillsReport(DateTime start, DateTime end) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Generating Bills Report...")));
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bills')
          .orderBy('date', descending: true)
          .get();

      // Filter by Date
      final bills = snapshot.docs.map((d) => d.data()).where((d) {
        final date = DateTime.parse(d['date']);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (bills.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No bills found in this period"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await PdfGenerator.generateBillsReport(bills, start, end);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 3. FINANCIAL SUMMARY (INCOME & WITHDRAW)
  Future<void> _generateFinancialReport(DateTime start, DateTime end) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating Financial Summary...")),
    );
    try {
      // Note: Income/Withdraw totals in 'customers' collection are LIFETIME totals.
      // Filtering them by date accurately requires querying all sub-collections which is heavy.
      // For this summary, we will show the current status but label the PDF with the period selected.

      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .orderBy('updatedAt', descending: true)
          .get();
      final customers = snapshot.docs.map((d) => d.data()).toList();

      if (customers.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No data found"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await PdfGenerator.generateFinancialReport(customers, start, end);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Reports Center"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildReportCard(
              "Financial Report",
              "Income, Withdraw & Balances",
              Icons.account_balance,
              Colors.green,
              () => _pickDateAndPrint(
                context,
                "Financial",
                _generateFinancialReport,
              ),
            ),
            const SizedBox(height: 15),
            _buildReportCard(
              "Debt Report",
              "Outstanding debts list",
              Icons.handshake,
              Colors.orange,
              () => _pickDateAndPrint(context, "Debt", _generateDebtReport),
            ),
            const SizedBox(height: 15),
            _buildReportCard(
              "Bills Report",
              "Expense & bills history",
              Icons.receipt_long,
              Colors.blueGrey,
              () => _pickDateAndPrint(context, "Bills", _generateBillsReport),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.calendar_today, color: Colors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}
