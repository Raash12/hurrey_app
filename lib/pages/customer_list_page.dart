// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hurrey_app/Auth/login_screen.dart'; // Hubi import-kan
// import 'add_customer_page.dart';
// import 'customer_detail_page.dart';

// class CustomerListPage extends StatefulWidget {
//   const CustomerListPage({super.key});

//   @override
//   State<CustomerListPage> createState() => _CustomerListPageState();
// }

// class _CustomerListPageState extends State<CustomerListPage> {
//   final TextEditingController _searchCtrl = TextEditingController();
//   String searchText = "";

//   void _confirmLogout() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: const Text("Logout"),
//         content: const Text("Are you sure you want to log out?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () async {
//               Navigator.pop(context);
//               await FirebaseAuth.instance.signOut();
//               if (mounted) {
//                 Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (_) => const LoginScreenModern()),
//                 );
//               }
//             },
//             child: const Text("Logout", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50], // Very light background
//       appBar: AppBar(
//         title: const Text(
//           "Customer Manager",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
//         ),
//         backgroundColor: Colors.blue[900],
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout_rounded),
//             onPressed: _confirmLogout,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 1. HEADER SEARCH AREA
//           Container(
//             padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
//             decoration: BoxDecoration(
//               color: Colors.blue[900],
//               borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(30),
//               ),
//             ),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _searchCtrl,
//                   style: const TextStyle(color: Colors.black87),
//                   decoration: InputDecoration(
//                     hintText: "Search by name or phone...",
//                     hintStyle: TextStyle(color: Colors.grey[400]),
//                     prefixIcon: const Icon(Icons.search, color: Colors.blue),
//                     filled: true,
//                     fillColor: Colors.white,
//                     contentPadding: const EdgeInsets.symmetric(vertical: 14),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(15),
//                       borderSide: BorderSide.none,
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(15),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   onChanged: (val) {
//                     setState(() {
//                       searchText = val.toLowerCase();
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // 2. LIST AREA
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection("customers")
//                   .orderBy("updatedAt", descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(child: Text("Error: ${snapshot.error}"));
//                 }

//                 final docs =
//                     snapshot.data?.docs.where((doc) {
//                       final data = doc.data() as Map<String, dynamic>;
//                       final name = (data["name"] ?? "")
//                           .toString()
//                           .toLowerCase();
//                       final phone = (data["phone"] ?? "")
//                           .toString()
//                           .toLowerCase();
//                       return name.contains(searchText) ||
//                           phone.contains(searchText);
//                     }).toList() ??
//                     [];

//                 if (docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.person_off_outlined,
//                           size: 60,
//                           color: Colors.grey[300],
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           searchText.isEmpty
//                               ? "No Customers Yet"
//                               : "No Match Found",
//                           style: TextStyle(
//                             color: Colors.grey[500],
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.separated(
//                   itemCount: docs.length,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 20,
//                   ),
//                   separatorBuilder: (ctx, i) => const SizedBox(height: 12),
//                   itemBuilder: (context, index) {
//                     final doc = docs[index];
//                     final data = doc.data() as Map<String, dynamic>;

//                     final double amountIn = (data['amountIn'] ?? 0).toDouble();
//                     final double amountOut = (data['amountOut'] ?? 0)
//                         .toDouble();
//                     final double balance = amountIn - amountOut;

//                     // Color logic: Green if positive, Red if negative, Grey if 0
//                     final balanceColor = balance > 0
//                         ? Colors.green[700]
//                         : (balance < 0 ? Colors.red[700] : Colors.grey[600]);

//                     final name = data["name"] ?? "No Name";
//                     final initial = name.isNotEmpty
//                         ? name.substring(0, 1).toUpperCase()
//                         : "?";

//                     return InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => CustomerDetailPage(
//                               customerId: doc.id,
//                               customerName: name,
//                               customerPhone: data["phone"] ?? "",
//                             ),
//                           ),
//                         );
//                       },
//                       borderRadius: BorderRadius.circular(16),
//                       child: Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.grey.withOpacity(0.08),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           children: [
//                             // AVATAR
//                             Container(
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: Colors.blue[50],
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   initial,
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue[900],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 15),

//                             // NAME & PHONE
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     name,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                       color: Colors.black87,
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     data["phone"] ?? "",
//                                     style: TextStyle(
//                                       color: Colors.grey[500],
//                                       fontSize: 13,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),

//                             // BALANCE
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   "\$${balance.abs().toStringAsFixed(2)}",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: balanceColor,
//                                   ),
//                                 ),
//                                 Text(
//                                   balance > 0
//                                       ? "Credit"
//                                       : (balance < 0 ? "Due" : "Settled"),
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w500,
//                                     color: balanceColor?.withOpacity(0.8),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(width: 8),
//                             Icon(Icons.chevron_right, color: Colors.grey[300]),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const AddCustomerPage()),
//           );
//         },
//         backgroundColor: const Color.fromARGB(255, 189, 192, 244),
//         icon: const Icon(Icons.add),
//         label: const Text("New Customer"),
//         elevation: 4,
//       ),
//     );
//   }
// }
