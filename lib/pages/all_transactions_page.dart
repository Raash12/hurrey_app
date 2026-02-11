import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return const Center(child: Text("No history found"));
          }

          return ListView.builder(
            itemCount: transactions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final t = transactions[index];
              final isPositive =
                  t['type'] == 'income' ||
                  t['type'] == 'in'; // income/in is positive
              final color = isPositive ? Colors.green : Colors.red;
              final icon = t['category'] == 'Bill'
                  ? Icons.receipt
                  : t['category'] == 'Debt'
                  ? Icons.monetization_on
                  : isPositive
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    t['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${t['date']} • ${t['category']}"),
                  trailing: Text(
                    "${isPositive ? '+' : '-'} \$${t['amount']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
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

  // Combine streams from different collections
  Stream<List<Map<String, dynamic>>> _getAllTransactions() {
    // Note: Firestore doesn't support easy multi-collection queries.
    // We will combine them manually in the stream.
    // Ideally, you should store all logs in a single 'transactions' collection for scalability.

    // For now, we will just fetch recent items from each and merge them in memory.
    // This is a simplified approach for your current structure.

    return Stream.fromFuture(Future.value([])).asyncMap((_) async {
      List<Map<String, dynamic>> allItems = [];

      // 1. Get Bills
      final bills = await FirebaseFirestore.instance.collection('bills').get();
      for (var doc in bills.docs) {
        allItems.add({
          'title': doc['name'],
          'amount': doc['amount'],
          'dateRaw': DateTime.parse(doc['date']),
          'date': DateFormat('dd MMM').format(DateTime.parse(doc['date'])),
          'type': 'expense',
          'category': 'Bill',
        });
      }

      // 2. Get Debts
      final debts = await FirebaseFirestore.instance.collection('debts').get();
      for (var doc in debts.docs) {
        allItems.add({
          'title': doc['name'],
          'amount': doc['amount'],
          'dateRaw': DateTime.parse(doc['date']),
          'date': DateFormat('dd MMM').format(DateTime.parse(doc['date'])),
          'type': 'expense', // Debt is money out/owed usually
          'category': 'Debt',
        });
      }

      // 3. Get Customer Transactions (Income/Withdraw)
      // This requires iterating customers which can be heavy.
      // BEST PRACTICE: When you add a transaction, also add it to a global 'history' collection.

      // Since we don't have a global history yet, we'll skip deep nested queries
      // to avoid performance issues, or you can implement a separate 'logs' collection.

      // Sorting
      allItems.sort((a, b) => b['dateRaw'].compareTo(a['dateRaw']));
      return allItems;
    });
  }
}
