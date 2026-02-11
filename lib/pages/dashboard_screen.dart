import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hurrey_app/Auth/login_screen.dart';
import 'section_list_page.dart';
import 'bills_page.dart';
import 'debt_page.dart';
import 'add_customer_page.dart';
import 'reports_page.dart'; // Make sure you have this file
import 'all_transactions_page.dart'; // <--- NEW FILE

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalIncome = 0;
  double totalWithdraw = 0;
  double totalBills = 0;
  double totalDebt = 0;
  double availableBalance = 0;

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreenModern()),
                );
              }
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
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text(
          "Hurey App",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.blue[800],
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- STREAMS ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, snapshotCust) {
                if (snapshotCust.hasData) {
                  double tempIn = 0;
                  double tempOut = 0;
                  for (var doc in snapshotCust.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    tempIn += (data['amountIn'] ?? 0).toDouble();
                    tempOut += (data['amountOut'] ?? 0).toDouble();
                  }
                  totalIncome = tempIn;
                  totalWithdraw = tempOut;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bills')
                      .snapshots(),
                  builder: (context, snapshotBills) {
                    if (snapshotBills.hasData) {
                      double tempBills = 0;
                      for (var doc in snapshotBills.data!.docs) {
                        tempBills += (doc['amount'] ?? 0).toDouble();
                      }
                      totalBills = tempBills;
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('debts')
                          .snapshots(),
                      builder: (context, snapshotDebt) {
                        if (snapshotDebt.hasData) {
                          double tempDebt = 0;
                          for (var doc in snapshotDebt.data!.docs) {
                            tempDebt += (doc['amount'] ?? 0).toDouble();
                          }
                          totalDebt = tempDebt;
                        }

                        availableBalance =
                            totalIncome - (totalWithdraw + totalBills);

                        return Column(
                          children: [
                            // --- MAIN CARD ---
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.account_balance_wallet,
                                          color: Colors.blue[800],
                                          size: 28,
                                        ),
                                      ),
                                      Icon(
                                        Icons.show_chart,
                                        color: Colors.blue[800],
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Available Balance",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),

                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "\$${availableBalance.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 25),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 0.2,
                                  ),
                                  const SizedBox(height: 15),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSimpleStat(
                                          "Total Income",
                                          totalIncome,
                                          Colors.green,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey[200],
                                      ),
                                      Expanded(
                                        child: _buildSimpleStat(
                                          "Total Withdraw",
                                          totalWithdraw,
                                          Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSimpleStat(
                                          "Total Bills",
                                          totalBills,
                                          Colors.blueGrey,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.grey[200],
                                      ),
                                      Expanded(
                                        child: _buildSimpleStat(
                                          "Total Debt",
                                          totalDebt,
                                          Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // --- QUICK ACCESS GRID ---
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Quick Access",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3, // 3 icons per row
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.0,
                              children: [
                                _buildGridItem(
                                  "Income",
                                  Icons.savings,
                                  Colors.green,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SectionListPage(
                                        type: SectionType.income,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildGridItem(
                                  "Debt",
                                  Icons.monetization_on,
                                  Colors.orange,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DebtPage(),
                                    ),
                                  ),
                                ),
                                _buildGridItem(
                                  "Withdraw",
                                  Icons.money_off,
                                  Colors.red,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SectionListPage(
                                        type: SectionType.withdraw,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildGridItem(
                                  "Bills",
                                  Icons.receipt,
                                  Colors.blueGrey,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BillsPage(),
                                    ),
                                  ),
                                ),
                                // REPORTS BUTTON ADDED HERE
                                _buildGridItem(
                                  "Reports",
                                  Icons.bar_chart,
                                  Colors.indigo,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReportsPage(),
                                    ),
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
              },
            ),
          ],
        ),
      ),

      // BOTTOM NAV
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(25),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.blue, size: 28),
              onPressed: () {},
            ),

            // ADD BUTTON
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCustomerPage()),
              ),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),

            // HISTORY BUTTON (LINKED)
            IconButton(
              icon: const Icon(Icons.history, color: Colors.grey, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AllTransactionsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            "\$${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
