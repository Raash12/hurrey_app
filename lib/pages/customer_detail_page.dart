import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_report_page.dart';
import 'edit_customer_page.dart'; // Hubi in faylkani jiro

class CustomerDetailPage extends StatefulWidget {
  final String customerId;
  final String name;

  const CustomerDetailPage({Key? key, required this.customerId, required this.name})
      : super(key: key);

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==================== SAVE TRANSACTION ====================
  Future<void> _saveTransaction({
    required double amount,
    required String description,
    required String type,
  }) async {
    final customerRef = FirebaseFirestore.instance.collection('addCustomer').doc(widget.customerId);
    final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(customerRef);
        final data = snapshot.data() as Map<String, dynamic>? ?? {};

        double balance = (data['totalBalance'] ?? 0).toDouble();
        double totalIn = (data['totalIn'] ?? 0).toDouble();
        double totalOut = (data['totalOut'] ?? 0).toDouble();
        double totalDebt = (data['totalDebt'] ?? 0).toDouble();

        double actualTransactionAmount = amount;
        bool shouldSaveTransaction = true;

        if (type == 'CASH_IN') {
          // 1) Bixi deynta marka hore
          if (totalDebt > 0) {
            if (amount >= totalDebt) {
              double remaining = amount - totalDebt;
              totalDebt = 0;
              totalIn += remaining;
              balance += remaining;
            } else {
              totalDebt -= amount;
              // lacagtu dhan bay deynta tagtay, balance iyo totalIn waxba kuma kordhin
            }
          } else {
            totalIn += amount;
            balance += amount;
          }
        } 
        else if (type == 'CASH_OUT') {
          totalOut += amount;
          balance -= amount;
        } 
        else if (type == 'DEBT') {
          // DEBT waxay isticmaashaa balance-ka haddii jiro, inta ka hartayna noqotaa debt
          if (balance > 0) {
            if (amount >= balance) {
              double remainingDebt = amount - balance;
              totalDebt += remainingDebt;
              balance = 0;
              actualTransactionAmount = amount; // kaydi heerka dhan
            } else {
              // lacagta oo dhan waxay ka tagtaa balance-ka, ma jiro debt cusub
              balance -= amount;
              shouldSaveTransaction = false; // ma kaydineyno transaction haddii aanay debt soo kordhin? Sida hore waxay ahayd true, laakiin haddii aad rabto in la kaydiyo isbeddel.
              // Aan ka dhigno true haddii aad rabto in waligood la kaydiyo
              shouldSaveTransaction = true;
              actualTransactionAmount = amount;
            }
          } else {
            // balance waa 0 ama ka hooseeya, debt-ga dhan
            totalDebt += amount;
          }
        }

        if (shouldSaveTransaction) {
          transaction.set(transactionRef, {
            'id': transactionRef.id,
            'customerId': widget.customerId,
            'amount': actualTransactionAmount,
            'description': description,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(customerRef, {
          'totalBalance': balance,
          'totalIn': totalIn,
          'totalOut': totalOut,
          'totalDebt': totalDebt,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      setState(() {});
    } catch (e) {
      debugPrint('Transaction error: $e');
    }
  }

  // ==================== EDIT TRANSACTION ====================
  Future<void> _editTransaction({
    required String transactionId,
    required double oldAmount,
    required String oldDescription,
    required String type,
  }) async {
    final amountCtrl = TextEditingController(text: oldAmount.toString());
    final descCtrl = TextEditingController(text: oldDescription);
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Edit Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const Divider(),
              const SizedBox(height: 10),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount (\$)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final a = double.tryParse(v);
                  if (a == null || a <= 0) return 'Enter positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, {
                      'amount': double.parse(amountCtrl.text.trim()),
                      'description': descCtrl.text.trim(),
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                child: const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      final newAmount = result['amount'] as double;
      final newDescription = result['description'] as String;

      final txRef = FirebaseFirestore.instance.collection('transactions').doc(transactionId);
      await txRef.update({
        'amount': newAmount,
        'description': newDescription,
        'createdAt': FieldValue.serverTimestamp(), // wakhti cusub si uu u soo baxo korka
      });

      // Dib u xisaabi dhammaan transactions-ka iyadoo la raacayo order-ka chronological
      await _recalculateCustomerTotalsFromTransactions();
    }
  }

  // ==================== RECALCULATE ALL TOTALS BY REPLAYING TRANSACTIONS ====================
  Future<void> _recalculateCustomerTotalsFromTransactions() async {
    final customerRef = FirebaseFirestore.instance.collection('addCustomer').doc(widget.customerId);
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('customerId', isEqualTo: widget.customerId)
        .orderBy('createdAt', descending: false) // chronological order
        .get();

    double balance = 0;
    double totalIn = 0;
    double totalOut = 0;
    double totalDebt = 0;

    for (var doc in transactionsSnapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String;
      double amount = (data['amount'] as num).toDouble(); // we store positive amount

      if (type == 'CASH_IN') {
        // Cash In: first reduce debt if any, then remainder to balance
        if (totalDebt > 0) {
          if (amount >= totalDebt) {
            double remaining = amount - totalDebt;
            totalDebt = 0;
            totalIn += remaining;
            balance += remaining;
          } else {
            totalDebt -= amount;
            // no addition to balance or totalIn
          }
        } else {
          totalIn += amount;
          balance += amount;
        }
      } 
      else if (type == 'CASH_OUT') {
        totalOut += amount;
        balance -= amount;
      } 
      else if (type == 'DEBT') {
        // Debt: first use available balance, remainder becomes debt
        if (balance > 0) {
          if (amount >= balance) {
            double remainingDebt = amount - balance;
            totalDebt += remainingDebt;
            balance = 0;
          } else {
            balance -= amount;
            // No debt added because amount fully covered by balance
          }
        } else {
          totalDebt += amount;
        }
      }
    }

    await customerRef.update({
      'totalBalance': balance,
      'totalIn': totalIn,
      'totalOut': totalOut,
      'totalDebt': totalDebt,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== UI MODALS ====================
  void _showTransactionModal(BuildContext context, String type, double currentBalance) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String title;
    Color color;
    if (type == 'CASH_IN') {
      title = 'Record Cash In (+)';
      color = const Color(0xFF065F46);
    } else if (type == 'CASH_OUT') {
      title = 'Record Cash Out (-)';
      color = const Color(0xFFB91C1C);
    } else {
      title = 'Record Debt (Dayn)';
      color = const Color(0xFFD97706);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModalHeader(ctx, title, color),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Available Net Balance: \$$currentBalance',
                  style: TextStyle(fontWeight: FontWeight.w600, color: type == 'CASH_OUT' ? Colors.red : Colors.grey),
                ),
              ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final amount = double.tryParse(v);
                  if (amount == null || amount <= 0) return 'Enter a positive number';
                  if (type == 'CASH_OUT' && amount > currentBalance) return 'Haraagu kuguma filna! Isticmaal DEBT hadii kale.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDescriptionField(descCtrl),
              const SizedBox(height: 20),
              _buildSaveButton(ctx, type, amountCtrl, descCtrl, formKey, color),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context, String title, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildDescriptionField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Description',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Enter a description' : null,
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    String type,
    TextEditingController amountCtrl,
    TextEditingController descCtrl,
    GlobalKey<FormState> formKey,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          final amount = double.parse(amountCtrl.text.trim());
          final desc = descCtrl.text.trim();
          Navigator.pop(context);
          await _saveTransaction(amount: amount, description: desc, type: type);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('SAVE TRANSACTION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  // ==================== DELETE CUSTOMER ====================
  void _deleteCustomer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 8), Text('Delete Customer?')]),
        content: const Text('This action is permanent and cannot be undone.', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('addCustomer').doc(widget.customerId).delete();
                final txs = await FirebaseFirestore.instance.collection('transactions').where('customerId', isEqualTo: widget.customerId).get();
                for (var doc in txs.docs) await doc.reference.delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer deleted')));
                }
              } catch (e) {
                debugPrint('Delete error: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C)),
            child: const Text('YES, DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD MAIN UI ====================
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const bgColor = Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('addCustomer').doc(widget.customerId).snapshots(),
          builder: (_, snapshot) {
            String displayName = widget.name;
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              displayName = data?['name'] ?? widget.name;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                const Text('Customer Ledger Details', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => EditCustomerPage(customerId: widget.customerId)));
              if (value == 'delete') _deleteCustomer(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, color: Colors.blue), SizedBox(width: 8), Text('Edit Profile')])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 8), Text('Delete Customer', style: TextStyle(color: Colors.red))])),
            ],
            icon: const Icon(Icons.more_vert, color: primaryColor),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('addCustomer').doc(widget.customerId).snapshots(),
        builder: (context, customerSnap) {
          if (customerSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (customerSnap.hasError) return Center(child: Text('Error: ${customerSnap.error}'));
          if (!customerSnap.hasData || customerSnap.data == null) return const Center(child: CircularProgressIndicator());

          final customerDoc = customerSnap.data!;
          if (!customerDoc.exists) return const Center(child: Text('Customer no longer exists.'));

          final data = customerDoc.data() as Map<String, dynamic>? ?? {};
          final balance = (data['totalBalance'] ?? 0).toDouble();
          final totalIn = data['totalIn'] ?? 0;
          final totalOut = data['totalOut'] ?? 0;
          final totalDebt = data['totalDebt'] ?? 0;
          final currentName = data['name'] ?? widget.name;

          return SafeArea(
            child: Column(
              children: [
                _buildSummaryCard(balance, totalIn, totalOut, totalDebt, currentName, context),
                _buildSearchBar(),
                Expanded(child: _buildTransactionList()),
                _buildActionButtons(context, balance),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: '🔍 Filter by description...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim().toLowerCase();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double balance, dynamic totalIn, dynamic totalOut, dynamic totalDebt, String customerName, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Net Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text('\$$balance', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ]),
            ),
            const Divider(height: 1, thickness: 1),
            _buildSummaryRow('Total In (+)', '\$$totalIn', const Color(0xFF065F46)),
            _buildSummaryRow('Total Out (-)', '\$$totalOut', const Color(0xFFB91C1C)),
            _buildSummaryRow('Total Debt', '\$$totalDebt', const Color(0xFFD97706)),
            const Divider(height: 1, thickness: 1),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionReportPage(customerId: widget.customerId, customerName: customerName))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('VIEW REPORTS ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A))),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').where('customerId', isEqualTo: widget.customerId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text('No transactions yet'));

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Try adding your first entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 12), Icon(Icons.arrow_downward, color: Color(0xFF2563EB), size: 32),
          ]));
        }

        // Filter by description
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final desc = (doc.data() as Map<String, dynamic>)['description'] ?? '';
            return desc.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        // Sort: newest first (by createdAt)
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final tx = docs[i].data() as Map<String, dynamic>;
            final txId = docs[i].id;
            final desc = tx['description'] ?? '';
            final amount = (tx['amount'] ?? 0).toDouble().abs();
            final type = tx['type'] ?? 'CASH_OUT';
            final timestamp = tx['createdAt'] as Timestamp?;
            final date = timestamp != null ? DateFormat('dd MMM yyyy • hh:mm a').format(timestamp.toDate()) : 'Just now';

            Color bgColor, textColor;
            String prefix;
            if (type == 'CASH_IN') {
              bgColor = const Color(0xFFECFDF5);
              textColor = const Color(0xFF065F46);
              prefix = '+ ';
            } else if (type == 'DEBT') {
              bgColor = const Color(0xFFFFF7ED);
              textColor = const Color(0xFFD97706);
              prefix = '⚠ ';
            } else {
              bgColor = const Color(0xFFFEF2F2);
              textColor = const Color(0xFFB91C1C);
              prefix = '- ';
            }

            return GestureDetector(
              onTap: () => _editTransaction(transactionId: txId, oldAmount: amount, oldDescription: desc, type: type),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(desc, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                        if (type == 'DEBT') Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                          child: const Text("DEBT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                      child: Text('$prefix\$$amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, double balance) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        _actionButton(context, 'CASH_IN', 'CASH IN', const Color(0xFF065F46), Icons.add, balance),
        const SizedBox(width: 12),
        _actionButton(context, 'CASH_OUT', 'CASH OUT', const Color(0xFFB91C1C), Icons.remove, balance),
        const SizedBox(width: 12),
        _actionButton(context, 'DEBT', 'DEBT', const Color(0xFFD97706), Icons.money_off_csred_rounded, balance),
      ]),
    );
  }

  Widget _actionButton(BuildContext context, String type, String label, Color color, IconData icon, double balance) {
    return Expanded(
      child: Column(children: [
        Text(_buttonCaption(type), style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        ElevatedButton.icon(
          onPressed: () => _showTransactionModal(context, type, balance),
          icon: Icon(icon, color: Colors.white, size: 16),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 1),
        ),
      ]),
    );
  }

  String _buttonCaption(String type) {
    switch (type) {
      case 'CASH_IN': return 'Record Income';
      case 'CASH_OUT': return 'Record Expense';
      case 'DEBT': return 'Record Debt';
      default: return '';
    }
  }
}