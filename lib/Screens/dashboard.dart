import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hurrey_app/Auth/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  // Colors
  static const Color primaryColor = Color(0xFF3B6CFF);
  static const Color backgroundColor = Color(0xFFE6E9EF);
  static const Color cardColor = Colors.white;
  static const Color subtitleColor = Color(0xFF9AA3AF);
  static const Color textDark = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 22, // smaller
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16, // smaller
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 18, color: subtitleColor),
            ),
          )
        ],
      ),

      // Body WITHOUT scrolling
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // tighter
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: const [
              _MonthlySummaryCard(),
              SizedBox(height: 10),
              _DailySpendsCard(),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        elevation: 3,
        mini: true, // smaller FAB
        child: const Icon(Icons.add, size: 22),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const _CurvedBottomBar(),
    );
  }
}

/* --------------------------- Header Summary Card --------------------------- */

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardScreen.primaryColor,
        borderRadius: BorderRadius.circular(14), // smaller radius
        boxShadow: [
          BoxShadow(
            color: DashboardScreen.primaryColor.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14), // tighter padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'January',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '\$ 500',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28, // smaller
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 6),
          _SummaryProgress(),
          SizedBox(height: 8),
          _DailyTargetPill(),
        ],
      ),
    );
  }
}

class _SummaryProgress extends StatelessWidget {
  const _SummaryProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.70,
              minHeight: 6, // thinner bar
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.insights, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        const Text(
          '70%',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}

class _DailyTargetPill extends StatelessWidget {
  const _DailyTargetPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Daily spend target: \$16.67',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/* ------------------------------ Daily Spends ------------------------------ */

class _DailySpendsCard extends StatelessWidget {
  const _DailySpendsCard();

  @override
  Widget build(BuildContext context) {
    final items = <_SpendItem>[
      _SpendItem(
        title: 'Net Banking',
        amount: 365.89,
        dateLabel: 'Today',
        color: const Color(0xFFFF7050),
        icon: Icons.account_balance,
      ),
      _SpendItem(
        title: 'Food & Drinks',
        amount: 165.99,
        dateLabel: '26 Jan, 2019',
        color: const Color(0xFFFFC120),
        icon: Icons.restaurant,
      ),
      _SpendItem(
        title: 'Clothes',
        amount: 65.09,
        dateLabel: '15 Jan, 2019',
        color: const Color(0xFF11C26D),
        icon: Icons.local_mall,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: DashboardScreen.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const _SectionHeader(title: 'DAILY SPENDS', onSeeAll: _noop),
          const SizedBox(height: 6),
          for (final s in items) _SpendTile(item: s),
        ],
      ),
    );
  }
}

void _noop() {}

class _SpendItem {
  final String title;
  final double amount;
  final String dateLabel;
  final IconData icon;
  final Color color;

  _SpendItem({
    required this.title,
    required this.amount,
    required this.dateLabel,
    required this.icon,
    required this.color,
  });
}

class _SpendTile extends StatelessWidget {
  final _SpendItem item;
  const _SpendTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6), // tighter
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: DashboardScreen.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: DashboardScreen.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.dateLabel,
            style: const TextStyle(
              color: DashboardScreen.subtitleColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------------- Fixed-size Wishlist ---------------------------- */


  


/* --------------------------- Section header row --------------------------- */

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: DashboardScreen.subtitleColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(6),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'See All',
              style: TextStyle(
                color: DashboardScreen.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Bottom App Bar ----------------------------- */

class _CurvedBottomBar extends StatelessWidget {
  const _CurvedBottomBar();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      elevation: 10,
      notchMargin: 6,
      color: Colors.white,
      child: SizedBox(
        height: 56, // shorter bar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.home_filled, size: 22)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_rounded, size: 22)),
            const SizedBox(width: 36), // space for mini FAB
            IconButton(onPressed: () {}, icon: const Icon(Icons.place_rounded, size: 22)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.person_rounded, size: 22)),
          ],
        ),
      ),
    );
  }
}
