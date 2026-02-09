import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateAndPrint(
    String name,
    String phone,
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> transactions,
  ) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd MMM yyyy');
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");

    // Xisaabi Wadarta (Totals)
    double totalIn = 0;
    double totalOut = 0;

    for (var t in transactions) {
      if (t['type'] == 'in') totalIn += (t['amount'] as num).toDouble();
      if (t['type'] == 'out') totalOut += (t['amount'] as num).toDouble();
    }
    double balance = totalIn - totalOut;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header (Cinwaanka)
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Statement of Account',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'App Name',
                    style: const pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 2. Customer Info & Date Range
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer:',
                      style: pw.TextStyle(color: PdfColors.grey600),
                    ),
                    pw.Text(
                      name,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    pw.Text(phone),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Statement Period:',
                      style: pw.TextStyle(color: PdfColors.grey600),
                    ),
                    pw.Text(
                      '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // 3. Table of Transactions
            pw.Table.fromTextArray(
              headers: ['Date', 'Description', 'Type', 'Amount'],
              data: transactions.map((t) {
                final date = DateTime.parse(t['date']);
                final amount = (t['amount'] as num).toDouble();
                final isDeposit = t['type'] == 'in';
                return [
                  dateFormatter.format(date),
                  t['description'] ?? '',
                  isDeposit ? 'Deposit' : 'Withdraw',
                  isDeposit
                      ? '+ ${currencyFormatter.format(amount)}'
                      : '- ${currencyFormatter.format(amount)}',
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight,
              }, // Amount right aligned
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
            ),
            pw.SizedBox(height: 20),

            // 4. Totals Summary
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Deposit:   + \$${currencyFormatter.format(totalIn)}',
                      style: const pw.TextStyle(color: PdfColors.green),
                    ),
                    pw.Text(
                      'Total Withdraw:   - \$${currencyFormatter.format(totalOut)}',
                      style: const pw.TextStyle(color: PdfColors.red),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Net Balance:   \$${currencyFormatter.format(balance)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Footer
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                "Generated by Customer Manager App",
                style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
              ),
            ),
          ];
        },
      ),
    );

    // Show Print Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Statement_$name.pdf',
    );
  }
}
