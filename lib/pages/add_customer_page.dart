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

    // 1. Prepare Customer Data
    final customerData = {
      "name": _nameCtrl.text,
      "phone": _phoneCtrl.text,
      "description": _descCtrl.text,
      "amountIn": inAmount,
      "amountOut": outAmount,
      "createdAt": DateTime.now().toIso8601String(),
    };

    try {
      // 2. Add Customer Document
      DocumentReference ref = await FirebaseFirestore.instance
          .collection("customers")
          .add(customerData);

      // 3. Create Initial Transaction Log (if money is added)
      final batch = FirebaseFirestore.instance.batch();

      if (inAmount > 0) {
        final transRef = ref.collection('transactions').doc();
        batch.set(transRef, {
          'amount': inAmount,
          'type': 'in',
          'date': DateTime.now().toIso8601String(),
          'description': 'Initial Opening Balance',
        });
      }

      if (outAmount > 0) {
        final transRef = ref.collection('transactions').doc();
        batch.set(transRef, {
          'amount': outAmount,
          'type': 'out',
          'date': DateTime.now().toIso8601String(),
          'description': 'Initial Opening Balance',
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer added successfully"),
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
            _buildTextField(_nameCtrl, "Name", Icons.person),
            const SizedBox(height: 16),
            _buildTextField(
              _phoneCtrl,
              "Phone",
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _descCtrl,
              "Description",
              Icons.description,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Opening Balance (Optional)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _inCtrl,
                    "Amount In (+)",
                    Icons.arrow_downward,
                    keyboardType: TextInputType.number,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _outCtrl,
                    "Amount Out (-)",
                    Icons.arrow_upward,
                    keyboardType: TextInputType.number,
                    color: Colors.red,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Customer",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    Color? color,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: color != null ? TextStyle(color: color) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon, color: color),
      ),
    );
  }
}
