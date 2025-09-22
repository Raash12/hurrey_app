import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_list_page.dart';

class EditCustomerPage extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> customerData;

  const EditCustomerPage({
    super.key,
    required this.customerId,
    required this.customerData,
  });

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _inCtrl;
  late TextEditingController _outCtrl;
  late TextEditingController _descCtrl; // <-- Description controller

  double newBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customerData["name"]);
    _phoneCtrl = TextEditingController(text: widget.customerData["phone"]);
    _descCtrl = TextEditingController(text: widget.customerData["description"] ?? ""); // <-- Init
    _inCtrl = TextEditingController();
    _outCtrl = TextEditingController();

    _calculateNewBalance();

    _inCtrl.addListener(_calculateNewBalance);
    _outCtrl.addListener(_calculateNewBalance);
  }

  void _calculateNewBalance() {
    final oldIn = (widget.customerData["amountIn"] ?? 0).toDouble();
    final oldOut = (widget.customerData["amountOut"] ?? 0).toDouble();
    final addIn = double.tryParse(_inCtrl.text) ?? 0;
    final addOut = double.tryParse(_outCtrl.text) ?? 0;

    setState(() {
      newBalance = (oldIn + addIn) - (oldOut + addOut);
    });
  }

  Future<void> _updateCustomer() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill name and phone fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final oldAmountIn = (widget.customerData["amountIn"] ?? 0).toDouble();
    final oldAmountOut = (widget.customerData["amountOut"] ?? 0).toDouble();

    final newAmountIn = double.tryParse(_inCtrl.text) ?? 0;
    final newAmountOut = double.tryParse(_outCtrl.text) ?? 0;

    final updatedAmountIn = oldAmountIn + newAmountIn;
    final updatedAmountOut = oldAmountOut + newAmountOut;

    final data = {
      "name": _nameCtrl.text,
      "phone": _phoneCtrl.text,
      "description": _descCtrl.text, // <-- Save description
      "amountIn": updatedAmountIn,
      "amountOut": updatedAmountOut,
      "updatedAt": DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection("customers")
        .doc(widget.customerId)
        .update(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Customer updated successfully"),
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
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _inCtrl.dispose();
    _outCtrl.dispose();
    _descCtrl.dispose(); // <-- Dispose description controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oldAmountIn = (widget.customerData["amountIn"] ?? 0).toDouble();
    final oldAmountOut = (widget.customerData["amountOut"] ?? 0).toDouble();
    final oldBalance = oldAmountIn - oldAmountOut;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Customer"),
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
                  labelText: "Add Amount In",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                  helperText: "Old In: $oldAmountIn",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _outCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Add Amount Out",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.arrow_upward, color: Colors.orange),
                  helperText: "Old Out: $oldAmountOut",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text("Old Balance: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "$oldBalance",
                    style: TextStyle(fontWeight: FontWeight.bold, color: oldBalance >= 0 ? Colors.green : Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("New Balance: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "$newBalance",
                    style: TextStyle(fontWeight: FontWeight.bold, color: newBalance >= 0 ? Colors.green : Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updateCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Update Customer", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
