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
        title: const Text("All Transactions History"),
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

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
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

              // Determine Color and Icon based on category
              Color color = Colors.grey;
              IconData icon = Icons.help;
              bool isPositive = false;

              if (t['category'] == 'Income') {
                color = Colors.green;
                icon = Icons.arrow_downward;
                isPositive = true;
              } else if (t['category'] == 'Withdraw') {
                color = Colors.red;
                icon = Icons.arrow_upward;
                isPositive = false;
              } else if (t['category'] == 'Bill') {
                color = Colors.blueGrey;
                icon = Icons.receipt;
                isPositive = false;
              } else if (t['category'] == 'Debt') {
                color = Colors.orange;
                icon = Icons.monetization_on;
                isPositive = false;
              }

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

  // --- MERGE ALL STREAMS ---
  Stream<List<Map<String, dynamic>>> _getAllTransactions() {
    // We combine distinct calls into one list using asyncMap
    return Stream.fromFuture(Future.value([])).asyncMap((_) async {
      List<Map<String, dynamic>> allItems = [];

      try {
        // 1. GET BILLS
        final bills = await FirebaseFirestore.instance
            .collection('bills')
            .get();
        for (var doc in bills.docs) {
          allItems.add({
            'title': doc['name'],
            'amount': (doc['amount'] ?? 0).toString(),
            'dateRaw': DateTime.parse(doc['date']),
            'date': DateFormat('dd MMM').format(DateTime.parse(doc['date'])),
            'category': 'Bill',
          });
        }

        // 2. GET DEBTS
        final debts = await FirebaseFirestore.instance
            .collection('debts')
            .get();
        for (var doc in debts.docs) {
          allItems.add({
            'title': doc['name'],
            'amount': (doc['amount'] ?? 0).toString(),
            'dateRaw': DateTime.parse(doc['date']),
            'date': DateFormat('dd MMM').format(DateTime.parse(doc['date'])),
            'category': 'Debt',
          });
        }

        // 3. GET CUSTOMER TRANSACTIONS (INCOME & WITHDRAW)
        // Using collectionGroup to find ALL subcollections named 'transactions'
        final customerTrans = await FirebaseFirestore.instance
            .collectionGroup('transactions')
            .get();

        for (var doc in customerTrans.docs) {
          final data = doc.data();
          bool isDeposit = data['type'] == 'in' || data['type'] == 'income';

          allItems.add({
            'title':
                data['description'] ?? (isDeposit ? "Deposit" : "Withdraw"),
            'amount': (data['amount'] ?? 0).toString(),
            'dateRaw': DateTime.parse(data['date']),
            'date': DateFormat('dd MMM').format(DateTime.parse(data['date'])),
            'category': isDeposit ? 'Income' : 'Withdraw',
          });
        }

        // 4. SORT BY DATE (NEWEST FIRST)
        allItems.sort((a, b) => b['dateRaw'].compareTo(a['dateRaw']));
      } catch (e) {
        debugPrint("Error fetching transactions: $e");
      }

      return allItems;
    });
  }
}
