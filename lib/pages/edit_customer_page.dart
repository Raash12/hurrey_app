import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCustomerPage extends StatefulWidget {
  final String customerId;

  // Sxb, halkan ka saar 'currentName' iyo 'currentPhone' waayo Firestore ayaan si toos ah uga aqrinaynaa hadda!
  const EditCustomerPage({super.key, required this.customerId});

  @override
  State<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers-ka hadda 'late' kama dhigin, si toos ah ayaan u bilownay
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching =
      true; // Waxay muujinaysaa in xogta la soo aqrinayo marka hore

  static const primaryColor = Color(0xFF0284C7);

  @override
  void initState() {
    super.initState();
    _loadCustomerData(); // Toos u soo aqri xogta marka bogga la furo sxb
  }

  // Shaqadan waxay si toos ah Firestore uga soo jiidaysa Magaca iyo Telifoonka rasmiga ah
  Future<void> _loadCustomerData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('addCustomer')
          .doc(widget.customerId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          // Labadii controller-na halkaan ayaan xogta dhabta ah ugu shubnay sxb
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _isFetching = false;
        });
      } else {
        setState(() => _isFetching = false);
      }
    } catch (e) {
      debugPrint("Error loading customer data: $e");
      setState(() => _isFetching = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Labadaba si wadajir ah ayay hadda u update-garoobayaan sxb (Name iyo Phone)
      await FirebaseFirestore.instance
          .collection('addCustomer')
          .doc(widget.customerId)
          .update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Xogta macaamiilka iyo telifoonka waa la cusboonaysiiyay!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Dib ugu laabo boggii hore adoo dhiirigelin wada
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cillad ayaa dhacday: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Wax ka baddal Macamiilka",
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      // Haddii xogta la soo aqrinayo ama la update-garaynayo, Loading tus sxb
      body: _isFetching || _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- TEXTFIELD MAGACA ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Magaca Macamiilka",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, color: primaryColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Fadlan magaca geli"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // --- TEXTFIELD TELIFOONKA (Hadda si sax ah ayuu u soo baxayaa sxb) ---
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Telifoonka",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone, color: primaryColor),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? "Fadlan telifoonka geli"
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // --- BUTTON-KA SAVE CHANGES ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
