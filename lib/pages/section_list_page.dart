import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_detail_page.dart';
import 'add_customer_page.dart';

enum SectionType { income, debt, withdraw }

class SectionListPage extends StatelessWidget {
  final SectionType type;

  const SectionListPage({super.key, required this.type});

  String get _title {
    switch (type) {
      case SectionType.income:
        return "Income Accounts";
      case SectionType.debt:
        return "Debt Accounts";
      case SectionType.withdraw:
        return "Withdrawals";
    }
  }

  Color get _color {
    switch (type) {
      case SectionType.income:
        return Colors.green;
      case SectionType.debt:
        return Colors.orange;
      case SectionType.withdraw:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // TOTAL HEADER
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('customers')
                .snapshots(),
            builder: (context, snapshot) {
              double total = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (type == SectionType.income) {
                    total += (data['amountIn'] ?? 0).toDouble();
                  } else if (type == SectionType.withdraw) {
                    total += (data['amountOut'] ?? 0).toDouble();
                  } else if (type == SectionType.debt) {
                    double bal =
                        (data['amountIn'] ?? 0) - (data['amountOut'] ?? 0);
                    if (bal < 0) total += bal.abs(); // Only negative balances
                  }
                }
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: _color.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      "TOTAL ${_title.toUpperCase()}",
                      style: TextStyle(
                        color: _color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "\$${total.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // Filter docs based on type
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  double i = (data['amountIn'] ?? 0).toDouble();
                  double o = (data['amountOut'] ?? 0).toDouble();

                  if (type == SectionType.income) return i > 0;
                  if (type == SectionType.withdraw) return o > 0;
                  if (type == SectionType.debt)
                    return (i - o) < 0; // Negative balance only
                  return true;
                }).toList();

                if (docs.isEmpty)
                  return const Center(child: Text("No accounts found"));

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    double i = (data['amountIn'] ?? 0).toDouble();
                    double o = (data['amountOut'] ?? 0).toDouble();
                    double val = 0;

                    if (type == SectionType.income) val = i;
                    if (type == SectionType.withdraw) val = o;
                    if (type == SectionType.debt) val = (i - o).abs();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _color.withOpacity(0.2),
                          child: Text(
                            data['name'].substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: _color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          data['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['phone'] ?? ""),
                        trailing: Text(
                          "\$${val.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _color,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailPage(
                                customerId: docs[index].id,
                                customerName: data['name'],
                                customerPhone: data['phone'],
                              ),
                            ),
                          );
                        },
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
