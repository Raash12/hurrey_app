import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'edit_customer_page.dart';

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
  // Function to add a transaction
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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

                  Navigator.pop(context); // Close dialog first

                  try {
                    // 1. Add to Transactions Sub-collection
                    await FirebaseFirestore.instance
                        .collection('customers')
                        .doc(widget.customerId)
                        .collection('transactions')
                        .add({
                          'amount': amount,
                          'type': isDeposit ? 'in' : 'out',
                          'date': DateTime.now().toIso8601String(),
                          'description': desc,
                        });

                    // 2. Update Main Customer Balance
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
                          'updatedAt': DateTime.now().toIso8601String(),
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
        content: const Text(
          "This will delete the customer and ALL their transaction history. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Note: Subcollections need to be deleted manually in Firestore usually,
              // but for simple apps, deleting the parent doc is often the first step.
              // Ideally, use a Cloud Function for recursive delete.
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(widget.customerId)
                  .delete();
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to list
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
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Only for editing Name/Phone/Desc. NOT Balance.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCustomerPage(
                    customerId: widget.customerId,
                    customerData: {
                      'name': widget.customerName,
                      'phone': widget.customerPhone,
                    }, // Simplified
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
          // Header Card with Live Balance
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
                          elevation: 0,
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
                          elevation: 0,
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

          // Transaction List
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
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text(
                        "No transactions yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isDeposit = data['type'] == 'in';
                    final date = DateTime.parse(data['date']);
                    // Using intl package for nice date
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
