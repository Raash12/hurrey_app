import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class AddCustomerPage extends StatefulWidget {
  final bool isWithdraw; // <--- CUSUB: Nooca account-ka

  const AddCustomerPage({
    super.key,
    this.isWithdraw = false,
  }); // Default is Income

  @override
  State<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends State<AddCustomerPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _balanceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  Future<void> _addCustomer() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill name and phone"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double amount = double.tryParse(_balanceCtrl.text) ?? 0;
    final now = DateTime.now().toIso8601String();

    // LOGIC: Withdraw miyaa mise Income?
    double amountIn = 0;
    double amountOut = 0;

    if (widget.isWithdraw) {
      amountOut = amount; // Withdraw
    } else {
      amountIn = amount; // Income
    }

    final customerData = {
      "name": _nameCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "amountIn": amountIn, // <--- Sax
      "amountOut": amountOut, // <--- Sax
      "createdAt": now,
      "updatedAt": now,
    };

    try {
      DocumentReference ref = await FirebaseFirestore.instance
          .collection("customers")
          .add(customerData);

      if (amount > 0) {
        await ref.collection('transactions').add({
          'amount': amount,
          'type': widget.isWithdraw ? 'out' : 'in', // Transaction Type sax ah
          'date': now,
          'description': 'Opening Balance',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Added"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
    // UI Colors based on type
    final primaryColor = widget.isWithdraw ? Colors.red : Colors.green;
    final title = widget.isWithdraw
        ? "New Withdraw Account"
        : "New Income Account";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField(_nameCtrl, "Name", Icons.person),
            const SizedBox(height: 15),
            _buildField(
              _phoneCtrl,
              "Phone",
              Icons.phone,
              type: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            _buildField(_descCtrl, "Description", Icons.notes, maxLines: 2),
            const SizedBox(height: 25),
            TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              decoration: InputDecoration(
                labelText: "amount in",
                prefixIcon: Icon(
                  widget.isWithdraw ? Icons.arrow_upward : Icons.arrow_downward,
                  color: primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save Account",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
