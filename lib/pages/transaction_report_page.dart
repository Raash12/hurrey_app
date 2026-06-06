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

  // --- DHALINTA PDF REPORT - KALIYA TRANSACTIONS LOGIC ---
  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();

    double totalCashIn = 0.0;
    double totalCashOut = 0.0;
    double totalDebt = 0.0;

    // KALIYA waxaan xogta ka xisaabinaynaa wixii ku jira transactions-ka la shaandheeyey sxb
    for (var doc in filteredDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final typeStr = data['type'] ?? 'N/A';
      final amountVal = (data['amount'] ?? 0.0).toDouble();

      if (typeStr == 'CASH_IN') {
        totalCashIn += amountVal;
      } else if (typeStr == 'CASH_OUT') {
        totalCashOut += amountVal;
      } else if (typeStr == 'DEBT') {
        totalDebt += amountVal;
      }
    }

    // XISAABTA DYNAMIC AH (CASH_IN iyo DEBT is-baxbaxooda):
    double calculatedIn = totalCashIn;
    double calculatedDebt = totalDebt;

    if (calculatedDebt > 0 && calculatedIn > 0) {
      if (calculatedIn >= calculatedDebt) {
        calculatedIn = calculatedIn - calculatedDebt;
        calculatedDebt = 0.0;
      } else {
        calculatedDebt = calculatedDebt - calculatedIn;
        calculatedIn = 0.0;
      }
    }

    // Net Balance-ka rasmiga ah (Lacagta nadiifka ah ee u hartay ama lagu leeyahay ka sokow deynta)
    double netBalance = calculatedIn - totalCashOut;

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
                  "Transaction Type: All Transactions",
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  "Period: ${startDate == null ? 'All Time' : DateFormat('dd MMM yyyy').format(startDate!)} - ${endDate == null ? 'All Time' : DateFormat('dd MMM yyyy').format(endDate!)}",
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Table Section
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

                String prefix = '';
                if (typeStr == 'CASH_IN') prefix = '+';
                if (typeStr == 'CASH_OUT' || typeStr == 'DEBT') prefix = '-';

                return [
                  dateStr,
                  data['description'] ?? '',
                  typeStr,
                  "$prefix\$$amountVal",
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
              cellAlignments: {3: pw.Alignment.centerRight},
            ),

            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // LABADA SANDUUQ OO KALIYA TRANSACTIONS KU TIIRSAN
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                // 1. Net Balance Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: netBalance < 0 ? PdfColors.red50 : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: netBalance < 0 ? PdfColors.red200 : PdfColors.green200),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        "Net Balance: ",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: netBalance < 0 ? PdfColors.red700 : PdfColors.green700,
                        ),
                      ),
                      pw.Text(
                        "${netBalance < 0 ? '-' : ''}\$${netBalance.abs().toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: netBalance < 0 ? PdfColors.red700 : PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                
                // 2. Total Debt Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.red200),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        "Total Debt (-): ",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700,
                        ),
                      ),
                      pw.Text(
                        "\$${calculatedDebt.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    const accentColor = Color(0xFF2563EB);

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
            // DROPDOWN BOX
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
                                      : DateFormat('dd MMM yyyy').format(startDate!),
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
                                      : DateFormat('dd MMM yyyy').format(endDate!),
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

            // STREAMBUILDER OO SOO AKHRINAYA TRANSACTIONS KALIYA
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

                  // Shaandheynta Taariikhda Start Date
                  if (startDate != null) {
                    docs = docs.where((doc) {
                      final time = (doc.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      return time != null &&
                          (time.toDate().isAfter(startDate!) ||
                              time.toDate().isAtSameMomentAs(startDate!));
                    }).toList();
                  }

                  // Shaandheynta Taariikhda End Date
                  if (endDate != null) {
                    docs = docs.where((doc) {
                      final time = (doc.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      return time != null &&
                          (time.toDate().isBefore(endDate!) ||
                              time.toDate().isAtSameMomentAs(endDate!));
                    }).toList();
                  }

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
                                "Total Transactions: ${docs.length}",
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
                      
                      // BUTTON-KA OO CO-ALL GAREYNAYA PDF-KA TOOSKA AH
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: docs.isEmpty 
                                ? null 
                                : () => _generatePdfReport(),
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