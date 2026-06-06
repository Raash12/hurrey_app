import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Si aad u qaabaysid taariikhda (Haddii aadan haysan run: flutter pub add intl)

class AllTransactionsPage extends StatelessWidget {
  final String customerId;
  final String customerName;

  const AllTransactionsPage({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          "$customerName - Transactions",
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🛑 Halkaan wuxuu ka akhrinayaa collection-ka GUUD ee 'transactions' isagoo ku shaandhaynaya customerId
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('customerId', isEqualTo: customerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No transactions found for this customer.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              double amount = (data['amount'] ?? 0).toDouble();
              String description = data['description'] ?? '';
              String type = data['type'] ?? 'CASH_IN';

              // Qaabaynta Taariikhda
              String formattedDate = "";
              if (data['createdAt'] != null) {
                DateTime dt = (data['createdAt'] as Timestamp).toDate();
                formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
              }

              bool isCashIn = type == 'CASH_IN';

              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.all(6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCashIn
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                    child: Icon(
                      isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCashIn
                          ? const Color(0xFF065F46)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                  title: Text(
                    description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Text(
                    "${isCashIn ? '+' : '-'}\$$amount",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCashIn
                          ? const Color(0xFF065F46)
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
