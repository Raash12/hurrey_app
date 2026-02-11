import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static final dateFormatter = DateFormat('dd MMM yyyy');
  static final currencyFormatter = NumberFormat("#,##0.00", "en_US");

  // --- 1. INDIVIDUAL STATEMENT (Income & Withdraw) ---
  static Future<void> generateStatement(
    String name,
    String phone,
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> transactions,
  ) async {
    final pdf = pw.Document();
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
        // FOOTER: Halkan ayaan ku xireynaa si uu bog walba ugu soo baxo hoosta
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            _buildHeader("Statement of Account"),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(name, phone, startDate, endDate),
            pw.SizedBox(height: 20),
            _buildTransactionTable(transactions),
            pw.Divider(),
            _buildSummary(totalIn, totalOut, balance),
          ];
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Statement_$name.pdf',
    );
  }

  // --- 2. FINANCIAL REPORT (Global Summary) ---
  static Future<void> generateFinancialReport(
    List<Map<String, dynamic>> customers,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();
    double totalIn = 0;
    double totalOut = 0;
    for (var c in customers) {
      totalIn += (c['amountIn'] ?? 0).toDouble();
      totalOut += (c['amountOut'] ?? 0).toDouble();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildHeader("General Financial Report"),
          pw.SizedBox(height: 10),
          pw.Text(
            "Period: ${dateFormatter.format(start)} - ${dateFormatter.format(end)}",
            style: pw.TextStyle(
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Name',
              'Phone',
              'Total Income',
              'Total Withdraw',
              'Balance',
            ],
            data: customers.map((c) {
              double i = (c['amountIn'] ?? 0).toDouble();
              double o = (c['amountOut'] ?? 0).toDouble();
              return [
                c['name'],
                c['phone'],
                currencyFormatter.format(i),
                currencyFormatter.format(o),
                currencyFormatter.format(i - o),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 20),
          _buildSummary(totalIn, totalOut, totalIn - totalOut),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Financial_Report.pdf',
    );
  }

  // --- 3. DEBT REPORT ---
  static Future<void> generateDebtReport(
    List<Map<String, dynamic>> debts,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();
    double totalDebt = 0;
    for (var d in debts) totalDebt += (d['amount'] as num).toDouble();

    pdf.addPage(
      pw.MultiPage(
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildHeader("Debt Report"),
          pw.SizedBox(height: 10),
          pw.Text(
            "Period: ${dateFormatter.format(start)} - ${dateFormatter.format(end)}",
            style: pw.TextStyle(
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Name', 'Date', 'Amount'],
            data: debts.map((d) {
              return [
                d['name'],
                dateFormatter.format(DateTime.parse(d['date'])),
                currencyFormatter.format(d['amount']),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.orange),
            cellAlignments: {2: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Total Debt: \$${currencyFormatter.format(totalDebt)}",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange,
              ),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Debt_Report.pdf',
    );
  }

  // --- 4. BILLS REPORT ---
  static Future<void> generateBillsReport(
    List<Map<String, dynamic>> bills,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();
    double totalBills = 0;
    for (var b in bills) totalBills += (b['amount'] as num).toDouble();

    pdf.addPage(
      pw.MultiPage(
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildHeader("Bills Report"),
          pw.SizedBox(height: 10),
          pw.Text(
            "Period: ${dateFormatter.format(start)} - ${dateFormatter.format(end)}",
            style: pw.TextStyle(
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Bill Name', 'Date', 'Amount'],
            data: bills.map((b) {
              return [
                b['name'],
                dateFormatter.format(DateTime.parse(b['date'])),
                currencyFormatter.format(b['amount']),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellAlignments: {2: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Total Bills: \$${currencyFormatter.format(totalBills)}",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Bills_Report.pdf',
    );
  }

  // --- HELPER WIDGETS ---
  static pw.Widget _buildHeader(String title) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Hurrey App',
            style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(
    String name,
    String phone,
    DateTime start,
    DateTime end,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Customer:', style: pw.TextStyle(color: PdfColors.grey600)),
            pw.Text(
              name,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.Text(phone),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Period:', style: pw.TextStyle(color: PdfColors.grey600)),
            pw.Text(
              '${dateFormatter.format(start)} - ${dateFormatter.format(end)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(
    List<Map<String, dynamic>> transactions,
  ) {
    return pw.Table.fromTextArray(
      headers: ['Date', 'Description', 'Type', 'Amount'],
      data: transactions.map((t) {
        final isDeposit = t['type'] == 'in';
        return [
          dateFormatter.format(DateTime.parse(t['date'])),
          t['description'] ?? '',
          isDeposit ? 'Deposit' : 'Withdraw',
          isDeposit
              ? '+ ${currencyFormatter.format(t['amount'])}'
              : '- ${currencyFormatter.format(t['amount'])}',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellAlignments: {3: pw.Alignment.centerRight},
    );
  }

  static pw.Widget _buildSummary(
    double totalIn,
    double totalOut,
    double balance,
  ) {
    return pw.Row(
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
            pw.Divider(),
            pw.Text(
              'Net Balance:   \$${currencyFormatter.format(balance)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ],
    );
  }

  // --- FIXED FOOTER (NO SPACER) ---
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        "Page ${context.pageNumber} of ${context.pagesCount} - Generated by Hurrey App",
        style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
      ),
    );
  }
}
