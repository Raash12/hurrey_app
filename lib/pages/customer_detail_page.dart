import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_customer_page.dart';
import 'pdf_generator.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  // ---------------- CUSTOM DATE PICKER & REPORT LOGIC ----------------

  void _showCustomDateRangePicker() {
    // Default: Bishan kowdeeda ilaa maanta
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
                  const Text(
                    "Select Period",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Text(
                    "Choose date range for report",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FROM DATE SELECTOR
                  _buildDateSelector(
                    label: "From:",
                    date: startDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => startDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  // TO DATE SELECTOR
                  _buildDateSelector(
                    label: "To:",
                    date: endDate,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => endDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close Dialog
                          _generateReport(startDate, endDate); // Generate PDF
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Print PDF"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              DateFormat('dd MMM yyyy').format(date),
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today, size: 18, color: Colors.blue[800]),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport(DateTime start, DateTime end) async {
    // Check Date Validity
    if (start.isAfter(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Start Date cannot be after End Date"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Generating PDF..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Fetch Data
      final querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(widget.customerId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      // Filter Data Locally
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final date = DateTime.parse(data['date']);
        // Normalize dates to remove time part for accurate comparison
        final normalizeDate = DateTime(date.year, date.month, date.day);
        final normalizeStart = DateTime(start.year, start.month, start.day);
        final normalizeEnd = DateTime(end.year, end.month, end.day);

        return (normalizeDate.isAtSameMomentAs(normalizeStart) ||
                normalizeDate.isAfter(normalizeStart)) &&
            (normalizeDate.isAtSameMomentAs(normalizeEnd) ||
                normalizeDate.isBefore(normalizeEnd));
      }).toList();

      if (filteredDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No transactions found in this period."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final transactions = filteredDocs.map((e) => e.data()).toList();

      // Call PDF Generator
      await PdfGenerator.generateAndPrint(
        widget.customerName,
        widget.customerPhone,
        start,
        end,
        transactions,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------- END REPORT LOGIC ----------------

  void _showTransactionDialog(BuildContext context, bool isDeposit) {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDeposit ? "Add Money (Deposit)" : "Take Money (Withdraw)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDeposit ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Description (Optional)",
                hintText: "e.g. Cash, Bank Transfer",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDeposit
                      ? Colors.green[700]
                      : Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final amountText = amountCtrl.text;
                  if (amountText.isEmpty) return;
                  final amount = double.tryParse(amountText);
                  if (amount == null || amount <= 0) return;

                  final desc = descCtrl.text.isEmpty
                      ? (isDeposit ? "Deposit" : "Withdrawal")
                      : descCtrl.text;

                  final now = DateTime.now().toIso8601String();

                  Navigator.pop(context);

                  try {
                    // Transaction Log
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(widget.customerId)
                        .collection('transactions')
                        .add({
                          'amount': amount,
                          'type': isDeposit ? 'in' : 'out',
                          'date': now,
                          'description': desc,
                        });

                    // Update Balance & updatedAt
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(widget.customerId)
                        .update({
                          'amountIn': isDeposit
                              ? FieldValue.increment(amount)
                              : FieldValue.increment(0),
                          'amountOut': !isDeposit
                              ? FieldValue.increment(amount)
                              : FieldValue.increment(0),
                          'updatedAt': now,
                        });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Transaction Saved"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  isDeposit ? "CONFIRM DEPOSIT" : "CONFIRM WITHDRAWAL",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Customer"),
        content: const Text("This will delete the customer. Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(widget.customerId)
                  .delete();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.customerName),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // CUSTOM PRINT BUTTON
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Print Statement",
            onPressed:
                _showCustomDateRangePicker, // <--- Wuxuu furayaa Dialog-ga cusub
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCustomerPage(
                    customerId: widget.customerId,
                    customerData: {
                      'name': widget.customerName,
                      'phone': widget.customerPhone,
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Total Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .doc(widget.customerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 40);
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) return const Text("Deleted");

                    final balance =
                        (data['amountIn'] ?? 0) - (data['amountOut'] ?? 0);
                    return Text(
                      "\$${balance.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_downward),
                        label: const Text("DEPOSIT"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showTransactionDialog(context, true),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text("WITHDRAW"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _showTransactionDialog(context, false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "History",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .doc(widget.customerId)
                  .collection('transactions')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No transactions yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isDeposit = data['type'] == 'in';
                    final date = DateTime.parse(data['date']);
                    final dateString = DateFormat('dd MMM yyyy').format(date);
                    final timeString = DateFormat('hh:mm a').format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDeposit
                                ? Colors.green[50]
                                : Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDeposit
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isDeposit ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          data['description'] ?? "Transaction",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "$dateString • $timeString",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        trailing: Text(
                          "${isDeposit ? '+' : '-'} \$${data['amount']}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDeposit
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
