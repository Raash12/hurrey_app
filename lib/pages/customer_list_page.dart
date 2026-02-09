import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_customer_page.dart';
import 'customer_detail_page.dart'; // Import-kan waa muhiim
import 'edit_customer_page.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String searchText = "";

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              // Halkan ku celi LoginScreen-kaaga
              // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreenModern()), (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
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
        title: const Text("Customer Manager"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[800],
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by name or phone...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  searchText = val.toLowerCase();
                });
              },
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("customers")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data["name"].toString().toLowerCase();
                  final phone = data["phone"].toString().toLowerCase();
                  return name.contains(searchText) ||
                      phone.contains(searchText);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No customers found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final balance =
                        (data["amountIn"] ?? 0) - (data["amountOut"] ?? 0);
                    final balanceColor = balance >= 0
                        ? Colors.green[700]
                        : Colors.red[700];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Go to Detail Page for Transactions
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailPage(
                                customerId: doc.id,
                                customerName: data["name"],
                                customerPhone: data["phone"],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  data["name"].substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data["name"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data["phone"],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$${balance.abs().toStringAsFixed(1)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: balanceColor,
                                    ),
                                  ),
                                  Text(
                                    balance >= 0 ? "Credit" : "Due",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: balanceColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
        },
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add),
      ),
    );
  }
}
