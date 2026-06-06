import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TransactionReportPage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const TransactionReportPage({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<TransactionReportPage> createState() => _TransactionReportPageState();
}

class _TransactionReportPageState extends State<TransactionReportPage> {
  String selectedFilter = 'ALL';
  DateTime? startDate;
  DateTime? endDate;
  List<DocumentSnapshot> filteredDocs = [];

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  // --- DHALINTA PDF REPORT (PRINT FUNCTION WITH ENGLISH & STYLING) ---
  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "TRANSACTION REPORT",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Customer: ${widget.customerName}",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  "Date: ${DateFormat('dd-MM-yyyy').format(DateTime.now())}",
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            // Filter Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Transaction Type: $selectedFilter",
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  "Period: ${startDate == null ? 'All Time' : DateFormat('dd MMM yyyy').format(startDate!)} - ${endDate == null ? 'All Time' : DateFormat('dd MMM yyyy').format(endDate!)}",
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // English Table with Styled Headers
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Type', 'Amount'],
              data: filteredDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final Timestamp? time = data['createdAt'] as Timestamp?;
                final dateStr = time != null
                    ? DateFormat('dd-MM-yyyy').format(time.toDate())
                    : '';
                final typeStr = data['type'] ?? 'N/A';
                final amountVal = data['amount'] ?? 0;

                return [
                  dateStr,
                  data['description'] ?? '',
                  typeStr,
                  typeStr == 'CASH_IN' ? "+\$$amountVal" : "-\$$amountVal",
                ];
              }).toList(),
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
              cellPadding: const pw.EdgeInsets.all(8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight,
              }, // Right align the amount column
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F172A);
    const accentColor = Color(0xFF2563EB); // Dynamic Blue for the button

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: primaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Filter Report",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // FILTERS SECTION (ENGLISH)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transaction Type",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFilter,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text("All Transactions"),
                          ),
                          DropdownMenuItem(
                            value: 'CASH_IN',
                            child: Text("Cash In (+)"),
                          ),
                          DropdownMenuItem(
                            value: 'CASH_OUT',
                            child: Text("Cash Out (-)"),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedFilter = value!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Date Range",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectStartDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  startDate == null
                                      ? "Start Date"
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(startDate!),
                                  style: TextStyle(
                                    color: startDate == null
                                        ? Colors.grey
                                        : primaryColor,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEndDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  endDate == null
                                      ? "End Date"
                                      : DateFormat(
                                          'dd MMM yyyy',
                                        ).format(endDate!),
                                  style: TextStyle(
                                    color: endDate == null
                                        ? Colors.grey
                                        : primaryColor,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ENGINE STREAM & PREVIEW
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('customerId', isEqualTo: widget.customerId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: accentColor),
                    );
                  }

                  var docs = snapshot.data?.docs ?? [];

                  // Sifaynta xogta (Filtering)
                  if (selectedFilter != 'ALL') {
                    docs = docs
                        .where(
                          (doc) =>
                              (doc.data() as Map<String, dynamic>)['type'] ==
                              selectedFilter,
                        )
                        .toList();
                  }
                  if (startDate != null) {
                    docs = docs.where((doc) {
                      final time =
                          (doc.data() as Map<String, dynamic>)['createdAt']
                              as Timestamp?;
                      return time != null &&
                          (time.toDate().isAfter(startDate!) ||
                              time.toDate().isAtSameMomentAs(startDate!));
                    }).toList();
                  }
                  if (endDate != null) {
                    docs = docs.where((doc) {
                      final time =
                          (doc.data() as Map<String, dynamic>)['createdAt']
                              as Timestamp?;
                      return time != null &&
                          (time.toDate().isBefore(endDate!) ||
                              time.toDate().isAtSameMomentAs(endDate!));
                    }).toList();
                  }

                  // Kaydi dukumiintiyada la sifeeyay
                  filteredDocs = docs;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: accentColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Filtered Results: ${docs.length} Transactions",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E40AF),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // STYLED PRINT BUTTON
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: docs.isEmpty ? null : _generatePdfReport,
                            icon: const Icon(Icons.print, color: Colors.white),
                            label: const Text(
                              "PRINT PDF REPORT",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              elevation: 2,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
