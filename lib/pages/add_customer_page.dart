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
  final TextEditingController _descCtrl = TextEditingController();

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

    final double inAmount = double.tryParse(_inCtrl.text) ?? 0;
    final double outAmount = double.tryParse(_outCtrl.text) ?? 0;
    final now = DateTime.now().toIso8601String();

    final customerData = {
      "name": _nameCtrl.text,
      "phone": _phoneCtrl.text,
      "description": _descCtrl.text,
      "amountIn": inAmount,
      "amountOut": outAmount,
      "createdAt": now,
      "updatedAt": now,
    };

    try {
      DocumentReference ref = await FirebaseFirestore.instance
          .collection("customers")
          .add(customerData);

      final batch = FirebaseFirestore.instance.batch();
      if (inAmount > 0) {
        batch.set(ref.collection('transactions').doc(), {
          'amount': inAmount,
          'type': 'in',
          'date': now,
          'description': 'Initial Balance',
        });
      }
      if (outAmount > 0) {
        batch.set(ref.collection('transactions').doc(), {
          'amount': outAmount,
          'type': 'out',
          'date': now,
          'description': 'Initial Balance',
        });
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer Added"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CustomerListPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Customer"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount In (+)",
                      prefixIcon: Icon(
                        Icons.arrow_downward,
                        color: Colors.green,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _outCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount Out (-)",
                      prefixIcon: Icon(Icons.arrow_upward, color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _addCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Customer"),
            ),
          ],
        ),
      ),
    );
  }
}
