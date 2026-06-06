import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_customer_page.dart';
import 'customer_detail_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const primaryColor = Color(0xFF1E3A8A);
  static const accentColor = Color(0xFF3B82F6);
  static const cardBgColor = Colors.white;

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');

  int _currentPageLimit = 10;
  static const int _perPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    _searchNotifier.dispose();
    super.dispose();
  }

  void _resetPagination() {
    if (_currentPageLimit != _perPage) {
      setState(() {
        _currentPageLimit = _perPage;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Ka Bax App-ka",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            "Ma hubtaa inaad rabto inaad ka baxdo (Logout) akoonkaaga hadda?",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Hubaal Maaha",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Waad ka baxday akoonkaaga!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Haa, Ka Bax",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          "Buugga Macaamiisha",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: primaryColor,
          ),
        ),
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
        stream: FirebaseFirestore.instance
            .collection('addCustomer')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Cillad ayaa dhacday: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          }

          final allDocs = snapshot.data?.docs ?? [];
          final stats = _calculateStats(allDocs);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsSection(stats),
              _buildSearchBar(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Macaamiisha Diiwángashan",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: _searchNotifier,
                  builder: (context, searchQuery, _) {
                    final filteredDocs = _filterCustomers(allDocs, searchQuery);
                    // Reset pagination when search query changes
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _resetPagination();
                    });
                    return _buildCustomerList(filteredDocs);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerPage()),
          );
        },
        backgroundColor: primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          "Macamiil Cusub",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // === STATS HELPERS ===
  _Stats _calculateStats(List<QueryDocumentSnapshot> docs) {
    double totalBalance = 0.0;
    double totalIn = 0.0;
    double totalOut = 0.0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalBalance += (data['totalBalance'] ?? 0.0).toDouble();
      totalIn += (data['totalIn'] ?? 0.0).toDouble();
      totalOut += (data['totalOut'] ?? 0.0).toDouble();
    }
    return _Stats(totalBalance: totalBalance, totalIn: totalIn, totalOut: totalOut);
  }

  Widget _buildStatsSection(_Stats stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMainStatCard(
            title: "Net Balance Guud",
            amount: stats.totalBalance,
            icon: Icons.account_balance_wallet_rounded,
            color: primaryColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSubStatCard(
                  title: "Total Cash In",
                  amount: stats.totalIn,
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubStatCard(
                  title: "Total Cash Out",
                  amount: stats.totalOut,
                  icon: Icons.arrow_upward_rounded,
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
        gradient: const LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "\$${amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
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
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === SEARCH BAR ===
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            _searchNotifier.value = value;
          },
          decoration: InputDecoration(
            hintText: "Ku raadi Magac ama Telifoon...",
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: accentColor),
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

  // === FILTER LOGIC ===
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

  // === CUSTOMER LIST WITH PAGINATION ===
  Widget _buildCustomerList(List<QueryDocumentSnapshot> customers) {
    final hasMore = customers.length > _currentPageLimit;
    final paginated = customers.take(_currentPageLimit).toList();

    if (paginated.isEmpty) {
      return const Center(
        child: Text(
          "Wax macamiil ah oo la mid ah lama helin.",
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: paginated.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == paginated.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentPageLimit += _perPage;
                });
              },
              icon: const Icon(Icons.expand_more_rounded, color: accentColor),
              label: const Text(
                "LOAD MORE (Soodari Macaamiil Kale)",
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
              ),
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
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerDetailPage(customerId: id, name: name),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_enabled_rounded, size: 13, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Haraaga",
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${balance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: balance < 0 ? const Color(0xFFEF4444) : primaryColor,
                      ),
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

// Helper class for stats
class _Stats {
  final double totalBalance;
  final double totalIn;
  final double totalOut;

  _Stats({required this.totalBalance, required this.totalIn, required this.totalOut});
}