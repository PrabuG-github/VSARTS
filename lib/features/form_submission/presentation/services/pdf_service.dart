import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/number_to_words.dart';
import '../../data/models/invoice_model.dart';

/// Generates a styled premium corporate PDF Invoice from an [InvoiceData] object.
class PdfService {
  // Brand color scheme (approximated in PdfColor)
  static const _primary = PdfColor.fromInt(0xFF6366F1);   // Indigo 500
  static const _secondary = PdfColor.fromInt(0xFF4F46E5); // Indigo 600
  static const _bgLight = PdfColor.fromInt(0xFFF8FAFC);
  static const _textDark = PdfColor.fromInt(0xFF0F172A);
  static const _textMuted = PdfColor.fromInt(0xFF475569);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _lightAccent = PdfColor.fromInt(0xFFEEF2F6);

  static Future<Uint8List> generateInvoicePdf(InvoiceData data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ');

          return pw.Stack(
            children: [
              // ─── Background ──────────────────────────────────
              pw.Positioned.fill(
                child: pw.Container(color: _bgLight),
              ),

              // ─── Top gradient header strip ────────────────────
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(
                  height: 140,
                  decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [_primary, _secondary],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // ─── Bottom accent strip ──────────────────────────
              pw.Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: pw.Container(
                  height: 6,
                  decoration: const pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [_primary, _secondary],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // ─── Main Contents ───────────────────────────────
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'VSARTS STUDIO',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Creative Print & Flex Solutions',
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                                ),
                                child: pw.Text(
                                  'INVOICE',
                                  style: pw.TextStyle(
                                    color: _secondary,
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Bill No: ${data.billNo}',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              pw.Text(
                                'Date: ${DateFormat('dd-MMM-yyyy').format(data.date)}',
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 45),

                      // Customer Information Card
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                          border: pw.Border.all(color: _border),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'CLIENT DETAILS',
                              style: pw.TextStyle(
                                color: _primary,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                        data.clientName,
                                        style: pw.TextStyle(
                                          color: _textDark,
                                          fontSize: 13,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.SizedBox(height: 4),
                                      pw.Text(
                                        data.address,
                                        style: const pw.TextStyle(
                                          color: _textMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text(
                                      'Phone',
                                      style: pw.TextStyle(
                                        color: _textMuted,
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      data.phoneNumber,
                                      style: pw.TextStyle(
                                        color: _textDark,
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      // Items Table
                      pw.Text(
                        'ITEM DETAILS',
                        style: pw.TextStyle(
                          color: _primary,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      pw.SizedBox(height: 8),

                      pw.Table(
                        border: const pw.TableBorder(
                          bottom: pw.BorderSide(color: _border, width: 0.5),
                          horizontalInside: pw.BorderSide(color: _border, width: 0.5),
                        ),
                        columnWidths: const {
                          0: pw.FixedColumnWidth(30),
                          1: pw.FlexColumnWidth(),
                          2: pw.FixedColumnWidth(65),
                          3: pw.FixedColumnWidth(65),
                          4: pw.FixedColumnWidth(40),
                          5: pw.FixedColumnWidth(75),
                          6: pw.FixedColumnWidth(85),
                        },
                        children: [
                          // Table Header
                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              color: _primary,
                              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                            ),
                            children: [
                              _tableHeaderCell('S.No', align: pw.TextAlign.center),
                              _tableHeaderCell('Description'),
                              _tableHeaderCell('Size (ft)', align: pw.TextAlign.center),
                              _tableHeaderCell('Area (Sq.Ft)', align: pw.TextAlign.right),
                              _tableHeaderCell('Qty', align: pw.TextAlign.center),
                              _tableHeaderCell('Rate', align: pw.TextAlign.right),
                              _tableHeaderCell('Total Price', align: pw.TextAlign.right),
                            ],
                          ),
                          // Table Rows
                          ...List.generate(data.items.length, (index) {
                            final item = data.items[index];
                            final isEven = index % 2 == 0;
                            return pw.TableRow(
                              decoration: pw.BoxDecoration(
                                color: isEven ? PdfColors.white : _bgLight,
                              ),
                              children: [
                                _tableCell('${index + 1}', align: pw.TextAlign.center),
                                _tableCell(item.description),
                                _tableCell('${item.length.toStringAsFixed(1)} x ${item.breadth.toStringAsFixed(1)}', align: pw.TextAlign.center),
                                _tableCell(item.area.toStringAsFixed(2), align: pw.TextAlign.right),
                                _tableCell('${item.quantity}', align: pw.TextAlign.center),
                                _tableCell(currencyFormatter.format(item.rate), align: pw.TextAlign.right),
                                _tableCell(currencyFormatter.format(item.price), align: pw.TextAlign.right),
                              ],
                            );
                          }),
                        ],
                      ),

                      pw.SizedBox(height: 25),

                      // Summary Card and Amount in Words
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Amount in words box on left
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(12),
                              decoration: const pw.BoxDecoration(
                                color: _lightAccent,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'AMOUNT IN WORDS',
                                    style: pw.TextStyle(
                                      color: _textMuted,
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Text(
                                    NumberToWords.convert(data.grandTotal),
                                    style: pw.TextStyle(
                                      color: _textDark,
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          // Totals column on right
                          pw.Expanded(
                            flex: 4,
                            child: pw.Column(
                              children: [
                                _summaryRow('Sub Total:', currencyFormatter.format(data.subTotal)),
                                pw.SizedBox(height: 6),
                                _summaryRow(
                                  'Extra Charges:',
                                  currencyFormatter.format(data.locationOutsideParrys ? data.extraCharges : 0.0),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Divider(color: _border, thickness: 1),
                                pw.SizedBox(height: 6),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Grand Total:',
                                      style: pw.TextStyle(
                                        color: _secondary,
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                    pw.Text(
                                      currencyFormatter.format(data.grandTotal),
                                      style: pw.TextStyle(
                                        color: _secondary,
                                        fontSize: 13,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.Spacer(),

                      // Footer signature & details
                      pw.Divider(color: _border, thickness: 1),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Terms & Conditions:',
                                style: pw.TextStyle(
                                  color: _textMuted,
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                '1. All prices are inclusive of standard local delivery.',
                                style: const pw.TextStyle(color: _textMuted, fontSize: 7),
                              ),
                              pw.Text(
                                '2. Interest at 18% p.a. will be charged for delayed payments.',
                                style: const pw.TextStyle(color: _textMuted, fontSize: 7),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Container(
                                width: 100,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.5)),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Authorized Signature',
                                style: pw.TextStyle(
                                  color: _textMuted,
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ─── Helper Widgets ──────────────────────────────────────────────────────────

  static pw.Widget _tableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(
          color: _textDark,
          fontSize: 8.5,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: _textMuted,
            fontSize: 9,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _textDark,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
