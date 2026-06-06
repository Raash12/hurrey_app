import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_report_page.dart';

class CustomerDetailPage extends StatelessWidget {
  final String customerId;
  final String name;

  const CustomerDetailPage({
    Key? key,
    required this.customerId,
    required this.name,
  }) : super(key: key);

  // --- FUNCTION: MODAL-KA CASH IN / CASH OUT ---
  void _openTransactionModal({
    required BuildContext context,
    required bool isCashIn,
    required double currentAvailableBalance,
  }) {
    final _amountController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCashIn ? "Record Cash In (+)" : "Record Cash Out (-)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCashIn
                            ? const Color(0xFF065F46)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                if (!isCashIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Available Balance: \$$currentAvailableBalance",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: "Amount (\$)",
                    hintText: "Enter amount",
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter an amount";
                    }
                    double? enteredAmount = double.tryParse(value);
                    if (enteredAmount == null || enteredAmount <= 0) {
                      return "Please enter a valid positive number";
                    }
                    // Halkan waxaa laga saaray validation-kii xannibayay haddii Cash Out uu ka weyn yahay Balance-ka.
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  keyboardType: TextInputType.text,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Description",
                    hintText: "Enter details (e.g., Payment for services)",
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a description";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      double amount = double.parse(
                        _amountController.text.trim(),
                      );
                      String description = _descriptionController.text.trim();

                      Navigator.pop(context);

                      await _saveTransactionToFirebase(
                        amount: amount,
                        description: description,
                        isCashIn: isCashIn,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCashIn
                        ? const Color(0xFF065F46)
                        : const Color(0xFFB91C1C),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "SAVE TRANSACTION",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- FIRESTORE DATABASE LOGIC ---
  Future<void> _saveTransactionToFirebase({
    required double amount,
    required String description,
    required bool isCashIn,
  }) async {
    final customerRef = FirebaseFirestore.instance
        .collection('addCustomer')
        .doc(customerId);
    final transactionRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot customerSnapshot = await transaction.get(customerRef);

        double currentBalance = 0.0;
        double currentTotalIn = 0.0;
        double currentTotalOut = 0.0;

        if (customerSnapshot.exists) {
          final data = customerSnapshot.data() as Map<String, dynamic>? ?? {};
          currentBalance = (data['totalBalance'] ?? 0).toDouble();
          currentTotalIn = (data['totalIn'] ?? 0).toDouble();
          currentTotalOut = (data['totalOut'] ?? 0).toDouble();
        }

        // Halkan laga saaray Exception-kii joojinayay transaction-ka marka uu balance-ku yaraado.

        if (isCashIn) {
          currentTotalIn += amount;
          currentBalance += amount;
        } else {
          currentTotalOut += amount;
          currentBalance -= amount;
        }

        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'customerId': customerId,
          'amount': isCashIn ? amount : -amount, 
          'description': description,
          'type': isCashIn ? 'CASH_IN' : 'CASH_OUT',
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(customerRef, {
          'totalBalance': currentBalance,
          'totalIn': currentTotalIn,
          'totalOut': currentTotalOut,
        });
      });
    } catch (e) {
      debugPrint("Error saving transaction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const backgroundColor = Color(0xFFF3F4F6);

    double latestBalance = 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              "Add Member, Book Activity etc",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('addCustomer')
              .doc(customerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            latestBalance = (data['totalBalance'] ?? 0).toDouble();
            dynamic totalIn = data['totalIn'] ?? 0;
            dynamic totalOut = data['totalOut'] ?? 0;

            return Column(
              children: [
                // --- KAAREEYAHA QIIMAHA (NET BALANCE) ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Net Balance",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                "\$$latestBalance",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total In (+)",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                "\$$totalIn",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Out (-)",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                "\$$totalOut",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- VIEW REPORTS BUTTON ---
                        const Divider(height: 1, thickness: 1),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionReportPage(
                                  customerId: customerId,
                                  customerName: name,
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "VIEW REPORTS ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Only you can see these entries",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // --- DHEXDA: TRANSACTION HISTORY ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('customerId', isEqualTo: customerId)
                        .snapshots(),
                    builder: (context, transactionSnapshot) {
                      if (transactionSnapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "Error loading transactions.\nDetails: ${transactionSnapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      if (!transactionSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      List<QueryDocumentSnapshot> docs =
                          transactionSnapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Try adding your first entry",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Icon(
                                Icons.arrow_downward,
                                color: Color(0xFF2563EB),
                                size: 32,
                              ),
                            ],
                          ),
                        );
                      }

                      // --- CLIENT-SIDE SORT ---
                      docs.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final Timestamp? aTime =
                            aData['createdAt'] as Timestamp?;
                        final Timestamp? bTime =
                            bData['createdAt'] as Timestamp?;

                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;

                        return bTime.compareTo(aTime);
                      });

                      return ListView.builder(
                        itemCount: docs.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final txData =
                              docs[index].data() as Map<String, dynamic>;
                          final String description =
                              txData['description'] ?? '';
                          final double amount = (txData['amount'] ?? 0)
                              .toDouble()
                              .abs(); 
                          final String type = txData['type'] ?? 'CASH_IN';
                          final Timestamp? createdAt =
                              txData['createdAt'] as Timestamp?;

                          bool isCashIn = type == 'CASH_IN';

                          String formattedDate = '';
                          if (createdAt != null) {
                            formattedDate = DateFormat(
                              'dd Jun yyyy • hh:mm a',
                            ).format(createdAt.toDate());
                          } else {
                            formattedDate = 'Just now';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCashIn
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${isCashIn ? '+ ' : '- '}\$$amount",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isCashIn
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // --- BUTTONS-KA HOOSE (CASH IN / CASH OUT) ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Record Income",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              onPressed: () => _openTransactionModal(
                                context: context,
                                isCashIn: true,
                                currentAvailableBalance: latestBalance,
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "CASH IN",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF065F46),
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              "Record Expense",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              onPressed: () => _openTransactionModal(
                                context: context,
                                isCashIn: false,
                                currentAvailableBalance: latestBalance,
                              ),
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "CASH OUT",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB91C1C),
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}