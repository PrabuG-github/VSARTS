import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/number_to_words.dart';
import '../../data/models/invoice_model.dart';

/// Generates a styled premium corporate PDF Invoice from an [InvoiceData] object.
class PdfService {
  // Brand color scheme matching the mockup
  static const _forestGreen = PdfColor.fromInt(0xFF0F5A41); // Deep Green
  static const _gold = PdfColor.fromInt(0xFFC5A880);        // Golden/Ochre Accent
  static const _bgLight = PdfColor.fromInt(0xFFFAF8F5);     // Cream/Off-white
  static const _textDark = PdfColor.fromInt(0xFF1E293B);    // Slate 800
  static const _textMuted = PdfColor.fromInt(0xFF64748B);   // Slate 500

  static Future<Uint8List> generateInvoicePdf(InvoiceData data) async {
    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(15),
        build: (pw.Context context) {
          final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ');

          // Helpers to draw the table cells
          final cellBorder = pw.BorderSide(color: _gold, width: 0.5);

          pw.Widget makeCell(String text, int flex, {pw.TextAlign align = pw.TextAlign.center, bool isHeader = false, bool isBold = false}) {
            return pw.Expanded(
              flex: flex,
              child: pw.Container(
                height: 20,
                alignment: align == pw.TextAlign.center
                    ? pw.Alignment.center
                    : (align == pw.TextAlign.left ? pw.Alignment.centerLeft : pw.Alignment.centerRight),
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: cellBorder,
                  ),
                ),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: isHeader ? 8.5 : 8,
                    fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: isHeader ? PdfColors.white : _textDark,
                  ),
                ),
              ),
            );
          }

          // Table row generator
          pw.Widget renderTableRow({
            required String sno,
            required String desc,
            required String size,
            required String qty,
            required String sqft,
            required String rate,
            required String price,
            bool isHeader = false,
          }) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                color: isHeader ? _forestGreen : PdfColors.white,
                border: pw.Border(
                  bottom: cellBorder,
                  left: cellBorder,
                ),
              ),
              child: pw.Row(
                children: [
                  makeCell(sno, 1, isHeader: isHeader),
                  makeCell(desc, 5, align: pw.TextAlign.left, isHeader: isHeader),
                  makeCell(size, 2, isHeader: isHeader),
                  makeCell(qty, 1, isHeader: isHeader),
                  makeCell(sqft, 2, isHeader: isHeader),
                  makeCell(rate, 2, align: pw.TextAlign.right, isHeader: isHeader),
                  makeCell(price, 2, align: pw.TextAlign.right, isHeader: isHeader, isBold: !isHeader),
                ],
              ),
            );
          }

          // Custom transportation row
          pw.Widget renderTransportationRow(String amount) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border(
                  bottom: cellBorder,
                  left: cellBorder,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 13,
                    child: pw.Container(
                      height: 20,
                      alignment: pw.Alignment.centerLeft,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: cellBorder,
                        ),
                      ),
                      child: pw.Text(
                        'Transportation Charges',
                        style: pw.TextStyle(
                          fontStyle: pw.FontStyle.italic,
                          fontWeight: pw.FontWeight.bold,
                          color: _forestGreen,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      height: 20,
                      alignment: pw.Alignment.centerRight,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: cellBorder,
                        ),
                      ),
                      child: pw.Text(
                        amount,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Totals block generator
          pw.Widget renderTotalsRow(String label, String value, {bool isGrandTotal = false}) {
            if (isGrandTotal) {
              return pw.Container(
                width: 220,
                margin: const pw.EdgeInsets.only(top: 4),
                decoration: const pw.BoxDecoration(
                  color: _forestGreen,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9.5,
                      ),
                    ),
                    pw.Text(
                      value,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              );
            }

            return pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _gold, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    label,
                    style: pw.TextStyle(
                      color: _textMuted,
                      fontSize: 8.5,
                    ),
                  ),
                  pw.Text(
                    value,
                    style: pw.TextStyle(
                      color: _textDark,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            );
          }

          // Generating the list of item rows (exactly 8 rows to match the mockup structure)
          final totalRowsCount = 8;
          final actualItemsCount = data.items.length;
          final List<pw.Widget> itemRows = [];

          for (int i = 0; i < totalRowsCount; i++) {
            if (i < actualItemsCount) {
              final item = data.items[i];
              itemRows.add(
                renderTableRow(
                  sno: '${i + 1}',
                  desc: item.description,
                  size: '${item.length.toStringAsFixed(0)} × ${item.breadth.toStringAsFixed(0)} ft',
                  qty: '${item.quantity}',
                  sqft: (item.quantity * item.area).toStringAsFixed(0),
                  rate: item.rate.toStringAsFixed(0),
                  price: currencyFormatter.format(item.price).replaceAll('₹ ', ''),
                ),
              );
            } else {
              // Empty rows for layout alignment
              itemRows.add(
                renderTableRow(
                  sno: '${i + 1}',
                  desc: '',
                  size: '',
                  qty: '',
                  sqft: '',
                  rate: '',
                  price: '',
                ),
              );
            }
          }

          return pw.Container(
            decoration: pw.BoxDecoration(
              color: _bgLight,
              border: pw.Border.all(color: _gold, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ─── Header Block ───────────────────────────────────────────
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: _forestGreen,
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(8.5)),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Row(
                    children: [
                      // Circular logo badge
                      pw.Container(
                        width: 72,
                        height: 72,
                        alignment: pw.Alignment.center,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(width: 20),
                      // Business Title Info Column
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              '✦   EST. 2000   ✦',
                              style: pw.TextStyle(
                                color: _gold,
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'VS ARTS',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 32,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            pw.Text(
                              'Flex & Banners',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 10,
                                fontStyle: pw.FontStyle.italic,
                                letterSpacing: 1.0,
                              ),
                            ),
                            pw.Container(
                              height: 0.5,
                              color: _gold,
                              margin: const pw.EdgeInsets.symmetric(vertical: 6),
                            ),
                            pw.Text(
                              '123, Anna Nagar, Chennai – 600 001, Tamil Nadu',
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 8,
                              ),
                            ),
                            pw.Text(
                              '📞 +91 98765 43210   |   ✉ vsarts@email.com',
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 8,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.RichText(
                              text: pw.TextSpan(
                                style: const pw.TextStyle(fontSize: 8),
                                children: [
                                  pw.TextSpan(
                                    text: 'Founder: ',
                                    style: pw.TextStyle(color: _gold, fontWeight: pw.FontWeight.bold),
                                  ),
                                  const pw.TextSpan(
                                    text: 'Murugesan   •   ',
                                    style: pw.TextStyle(color: PdfColors.white),
                                  ),
                                  pw.TextSpan(
                                    text: 'Managing Director: ',
                                    style: pw.TextStyle(color: _gold, fontWeight: pw.FontWeight.bold),
                                  ),
                                  const pw.TextSpan(
                                    text: 'Srimukesh Murugesan',
                                    style: pw.TextStyle(color: PdfColors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Symmetrical spacing column
                      pw.SizedBox(width: 72),
                    ],
                  ),
                ),

                // ─── Bill Details Strip ──────────────────────────────────────
                pw.Container(
                  height: 26,
                  decoration: const pw.BoxDecoration(
                    color: _forestGreen,
                    border: pw.Border.symmetric(
                      horizontal: pw.BorderSide(color: _gold, width: 1),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'BILL NO. ${data.billNo}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.5,
                        ),
                      ),
                      pw.Text(
                        '✦   INVOICE / BILL   ✦',
                        style: pw.TextStyle(
                          color: _gold,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                      pw.Text(
                        'DATE ${DateFormat('dd / MM / yyyy').format(data.date)}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Customer details "Bill To" ──────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '✦ BILL TO',
                        style: pw.TextStyle(
                          color: _forestGreen,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Client Name
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              margin: const pw.EdgeInsets.only(right: 12),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: _gold, width: 0.8),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'CLIENT NAME',
                                    style: pw.TextStyle(color: _textMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    data.clientName,
                                    style: pw.TextStyle(color: _textDark, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Address
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              margin: const pw.EdgeInsets.only(right: 12),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: _gold, width: 0.8),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'ADDRESS',
                                    style: pw.TextStyle(color: _textMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    data.address,
                                    style: pw.TextStyle(color: _textDark, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Phone
                          pw.Expanded(
                            flex: 3,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(color: _gold, width: 0.8),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'PHONE NO.',
                                    style: pw.TextStyle(color: _textMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    data.phoneNumber,
                                    style: pw.TextStyle(color: _textDark, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ─── Items Table ─────────────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        top: cellBorder,
                        right: cellBorder,
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        // Header
                        renderTableRow(
                          sno: 'S.No',
                          desc: 'Description of Work',
                          size: 'Size',
                          qty: 'Qty',
                          sqft: 'Sq. Feet',
                          rate: 'Rate (₹)',
                          price: 'Price (₹)',
                          isHeader: true,
                        ),
                        // List items
                        ...itemRows,
                        // Transportation row
                        renderTransportationRow(
                          data.locationOutsideParrys
                              ? currencyFormatter.format(data.extraCharges).replaceAll('₹ ', '')
                              : '0.00',
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Totals and Summary Section ──────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.SizedBox(width: 1), // spacer on left
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          renderTotalsRow('Sub Total', currencyFormatter.format(data.subTotal)),
                          renderTotalsRow(
                            'Transportation Charges',
                            data.locationOutsideParrys
                                ? currencyFormatter.format(data.extraCharges)
                                : currencyFormatter.format(0.0),
                          ),
                          renderTotalsRow('Tax (10%)', currencyFormatter.format(data.tax)),
                          renderTotalsRow('GRAND TOTAL', currencyFormatter.format(data.grandTotal), isGrandTotal: true),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ─── Amount in Words Box ─────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFEEF7F4),
                      border: pw.Border.all(color: _gold, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(
                            text: 'AMOUNT IN WORDS: ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: _forestGreen,
                              fontSize: 8.5,
                            ),
                          ),
                          pw.TextSpan(
                            text: '${NumberToWords.convert(data.grandTotal)} Only',
                            style: pw.TextStyle(
                              fontStyle: pw.FontStyle.italic,
                              color: _textDark,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 8),

                // ─── Note warning Box ────────────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFFFBEB), // Amber tint
                      border: pw.Border.all(color: _gold, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          '⚠️  ',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Expanded(
                          child: pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Note: ',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFFB45309),
                                    fontSize: 8.5,
                                  ),
                                ),
                                const pw.TextSpan(
                                  text: 'If the shop location is out from Parrys, extra charges will be applicable.',
                                  style: pw.TextStyle(
                                    color: _textDark,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 25),

                // ─── Footer Signatures Section ───────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Thank you for your business!',
                            style: pw.TextStyle(
                              color: _forestGreen,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9.5,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'For queries: +91 98765 43210',
                            style: pw.TextStyle(
                              color: _textMuted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            height: 0.5,
                            color: _textDark,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Customer Signature',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: _textDark,
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            'Name & Date',
                            style: pw.TextStyle(
                              color: _textMuted,
                              fontSize: 7,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 140,
                            height: 0.5,
                            color: _textDark,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Srimukesh Murugesan',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: _textDark,
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            'Managing Director, VS Arts',
                            style: pw.TextStyle(
                              color: _textMuted,
                              fontSize: 7,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
