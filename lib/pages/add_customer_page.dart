import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_list_page.dart';

class AddCustomerPage extends StatefulWidget {
  const AddCustomerPage({super.key});

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _inCtrl = TextEditingController();
  final TextEditingController _outCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController(); // <-- Description controller

  Future<void> _addCustomer() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill name and phone fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      "name": _nameCtrl.text,
      "phone": _phoneCtrl.text,
      "description": _descCtrl.text,  // <-- Save description
      "amountIn": double.tryParse(_inCtrl.text) ?? 0,
      "amountOut": double.tryParse(_outCtrl.text) ?? 0,
      "createdAt": DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance.collection("customers").add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Customer added successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Go directly to Customer List
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerListPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Customer"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl, // <-- Description field
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount In",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Add Customer", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _inCtrl.dispose();
    _outCtrl.dispose();
    _descCtrl.dispose(); // <-- Dispose description controller
    super.dispose();
  }
}
