import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hurrey_app/Auth/login_screen.dart';
import 'add_customer_page.dart';
import 'customer_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const primaryColor = Color(0xFF0284C7);
  static const accentColor = Color(0xFF38BDF8);
  static const lightBgColor = Color(0xFFF0F9FF);
  static const cardBgColor = Colors.white;

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');
  bool _isCustomerListExpanded = false;
  int _currentPageLimit = 10;
  static const int _perPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text("Ka Bax App-ka", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            "Ma hubtaa inaad rabto inaad ka baxdo (Logout) akoonkaaga hadda?",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hubaal Maaha", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Waad ka baxday akoonkaaga sxb!"), backgroundColor: primaryColor),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreenModern()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Cillad ayaa dhacday xilligii logout-ka: $e"), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Haa, Ka Bax", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: primaryColor)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 26),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('addCustomer').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Cillad ayaa dhacday: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          var allDocs = snapshot.data?.docs ?? [];

          // Sorting
          allDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final DateTime timeA = (dataA['updatedAt'] as Timestamp?)?.toDate() ??
                (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final DateTime timeB = (dataB['updatedAt'] as Timestamp?)?.toDate() ??
                (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });

          final stats = _calculateStats(allDocs);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsSection(stats),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100, width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _isCustomerListExpanded = !_isCustomerListExpanded),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.supervised_user_circle_rounded, color: primaryColor, size: 24),
                                  const SizedBox(width: 10),
                                  const Text("List Customer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: lightBgColor, borderRadius: BorderRadius.circular(10)),
                                    child: Text("${allDocs.length}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                                  ),
                                ],
                              ),
                              Icon(_isCustomerListExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isCustomerListExpanded)
                  ValueListenableBuilder<String>(
                    valueListenable: _searchNotifier,
                    builder: (context, searchQuery, _) {
                      final filteredDocs = _filterCustomers(allDocs, searchQuery);
                      return _buildCustomerList(filteredDocs);
                    },
                  )
                else
                  const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerPage())),
        backgroundColor: primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text("new Customer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  _Stats _calculateStats(List<QueryDocumentSnapshot> docs) {
    double totalNetBalance = 0.0;
    double totalOut = 0.0;
    double totalDebt = 0.0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final currentBalance = (data['totalBalance'] ?? 0.0).toDouble();
      if (currentBalance >= 0) totalNetBalance += currentBalance;
      totalOut += (data['totalOut'] ?? 0.0).toDouble();
      totalDebt += (data['totalDebt'] ?? 0.0).toDouble();
    }
    return _Stats(totalNetBalance: totalNetBalance, totalOut: totalOut, totalDebt: totalDebt);
  }

  Widget _buildStatsSection(_Stats stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMainStatCard(
            title: "Total Net Balance (+)",
            amount: stats.totalNetBalance,
            icon: Icons.account_balance_wallet_rounded,
            color: primaryColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSubStatCard(
                  title: "Total Cash Out",
                  amount: stats.totalOut,
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubStatCard(
                  title: "Total Debt (Deynta Guud)",
                  amount: stats.totalDebt,
                  icon: Icons.remove_circle_outline_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryColor, accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text("\$${amount.toStringAsFixed(2)}", style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => _searchNotifier.value = value,
          decoration: InputDecoration(
            hintText: "Ku raadi Magac ama Telifoon...",
            hintStyle: TextStyle(color: Colors.blue.shade300, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _searchNotifier,
              builder: (context, query, _) {
                return query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchNotifier.value = "";
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterCustomers(List<QueryDocumentSnapshot> docs, String searchQuery) {
    if (searchQuery.trim().isEmpty) return docs;
    final query = searchQuery.trim().toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().trim().toLowerCase();
      final phone = (data['phone'] ?? '').toString().trim().toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  Widget _buildCustomerList(List<QueryDocumentSnapshot> customers) {
    final hasMore = customers.length > _currentPageLimit;
    final paginated = customers.take(_currentPageLimit).toList();

    if (paginated.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text("Wax macamiil ah oo la mid ah lama helin.", style: TextStyle(color: Colors.grey, fontSize: 15)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      itemCount: paginated.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == paginated.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton.icon(
              onPressed: () => setState(() => _currentPageLimit += _perPage),
              icon: const Icon(Icons.expand_more_rounded, color: primaryColor),
              label: const Text("LOAD MORE (Soodari Macaamiil Kale)", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          );
        }
        final doc = paginated[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildCustomerItem(
          id: doc.id,
          name: data['name'] ?? 'Magac la\'aan',
          phone: data['phone'] ?? 'Telifoon la\'aan',
          balance: (data['totalBalance'] ?? 0.0).toDouble(),
        );
      },
    );
  }

  Widget _buildCustomerItem({
    required String id,
    required String name,
    required String phone,
    required double balance,
  }) {
    final firstLetter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "M";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade50, width: 1),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerDetailPage(customerId: id, name: name))),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: lightBgColor,
                  child: Text(firstLetter, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_enabled_rounded, size: 13, color: Colors.blue.shade300),
                          const SizedBox(width: 4),
                          Text(phone, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Haraaga", style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      "\$${balance.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: balance < 0 ? const Color(0xFFEF4444) : primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stats {
  final double totalNetBalance;
  final double totalOut;
  final double totalDebt;
  _Stats({required this.totalNetBalance, required this.totalOut, required this.totalDebt});
}