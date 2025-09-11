import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hurrey_app/Auth/login_screen.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isCollapsed = true;

  final List<String> imagePaths = [
    'image/img1.jpg',
    'image/img2.jpg',
    'image/img3.jpg',
    'image/img4.jpg',
  ];

  final List<String> titles = [
    'Luxury Retreat',
    'Modern Haven',
    'Eco Smart Living',
    'Family Comfort Space',
  ];

  final List<String> descriptions = [
    'Experience unmatched comfort and elegance.',
    'A modern sanctuary with premium finishes.',
    'Eco-conscious living with smart design.',
    'Spacious, safe, and perfect for your family.',
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  int apartmentCount = 0;
  int requestCount = 0;
  int rentedCount = 0;
  int materialPendingCount = 0;
  int materialApprovedCount = 0;
  int identificationApprovedCount = 0;
  int identificationPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoPlay();
    _fetchCounts();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_currentPage < imagePaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuint,
        );
      }
      _startAutoPlay();
    });
  }

  Future<void> _fetchCounts() async {
    final firestore = FirebaseFirestore.instance;

    final apartments = await firestore.collection('apartments').get();
    final identifications = await firestore.collection('identifications').get();
    final rentNow = await firestore.collection('rentals').get();

    final materialPending = await firestore
        .collection('material_requests')
        .where('status', isEqualTo: 'pending')
        .get();

    final materialApproved = await firestore
        .collection('material_requests')
        .where('status', isEqualTo: 'approved')
        .get();

    final identificationApproved = await firestore
        .collection('identifications')
        .where('status', isEqualTo: 'Approved')
        .get();

    final identificationPending = await firestore
        .collection('identifications')
        .where('status', isEqualTo: 'Pending')
        .get();

    setState(() {
      apartmentCount = apartments.docs.length;
      requestCount = identifications.docs.length;
      rentedCount = rentNow.docs.length;
      materialPendingCount = materialPending.docs.length;
      materialApprovedCount = materialApproved.docs.length;
      identificationApprovedCount = identificationApproved.docs.length;
      identificationPendingCount = identificationPending.docs.length;
    });
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    final gradientColors = _getCardGradient(color);
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Container(
        height: 60, // Updated height to 60 pixels
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getCardGradient(Color baseColor) {
    if (baseColor == Colors.green) {
      return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
    } else if (baseColor == Colors.blue) {
      return [const Color(0xFF2196F3), const Color(0xFF64B5F6)];
    } else if (baseColor == Colors.orange) {
      return [const Color(0xFFFF9800), const Color(0xFFFFC107)];
    } else if (baseColor == Colors.purple) {
      return [const Color(0xFF9C27B0), const Color(0xFFBA68C8)];
    } else {
      return [baseColor.withOpacity(0.8), baseColor.withOpacity(0.4)];
    }
  }

  Widget _buildStatsGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 24;
        final crossAxisCount = (availableWidth / 150).floor().clamp(1, 4); // Allow more columns
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.8, // Adjusted for horizontal layout
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: cards,
        );
      },
    );
  }

  Widget _buildIdentificationStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Identification Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        _buildStatsGrid([
          _buildStatCard(
            'Approved',
            identificationApprovedCount.toString(),
            Icons.verified,
            Colors.green,
          ),
          _buildStatCard(
            'Pending',
            identificationPendingCount.toString(),
            Icons.pending,
            Colors.orange,
          ),
          _buildStatCard(
            'Total',
            requestCount.toString(),
            Icons.assignment,
            Colors.deepPurple,
          ),
        ]),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
        _buildStatsGrid([
          _buildStatCard(
            'Apartments', 
            apartmentCount.toString(),
            Icons.apartment, 
            Colors.indigo
          ),
          _buildStatCard(
            'Rented', 
            rentedCount.toString(),
            Icons.car_rental, 
            Colors.teal
          ),
          _buildStatCard(
            'Pending Material', 
            materialPendingCount.toString(),
            Icons.pending_actions, 
            Colors.amber
          ),
          _buildStatCard(
            'Approved Material', 
            materialApprovedCount.toString(),
            Icons.check_circle_outline, 
            Colors.lightGreen
          ),
        ]),
      ],
    );
  }

  Widget _buildSidebar() {
    if (_isCollapsed) return const SizedBox.shrink();
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Center(
              child: Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                
                _buildSidebarItem(Icons.logout, 'Logout', LoginScreenModern(), isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, Widget targetPage, {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.deepPurple),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 10,
        horizontalTitleGap: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          if (isLogout) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => targetPage),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => targetPage),
            );
          }
        },
      ),
    );
  }


  Widget _buildRequestsButton() {
    return IconButton(
      icon: const Icon(Icons.mark_as_unread_sharp, color: Colors.deepPurple),
      onPressed: () {
        
      },
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isCollapsed ? Icons.menu : Icons.close, color: Colors.deepPurple),
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildRequestsButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imagePaths.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
              }
              return Transform.scale(scale: value, child: child);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(imagePaths[index], fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 30,
                      child: Text(
                        titles[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 12,
                      child: Text(
                        descriptions[index],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToggleButton(),
                          const SizedBox(height: 10),
                          _buildCarousel(),
                          _buildStatsCards(),
                          _buildIdentificationStats(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}