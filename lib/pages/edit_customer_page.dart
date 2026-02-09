import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.customerData["name"]);
    _phoneCtrl = TextEditingController(text: widget.customerData["phone"]);
    _descCtrl = TextEditingController(
      text: widget.customerData["description"] ?? "",
    );
  }

  Future<void> _updateCustomer() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;

    // ISBEDELKA: Halkan 'updatedAt' ayaan ku darnay
    await FirebaseFirestore.instance
        .collection("customers")
        .doc(widget.customerId)
        .update({
          "name": _nameCtrl.text,
          "phone": _phoneCtrl.text,
          "description": _descCtrl.text,
          "updatedAt": DateTime.now()
              .toIso8601String(), // <--- MUHIIM: Update time
        });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _updateCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Update Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
