import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/number_to_words.dart';
import '../../data/models/invoice_model.dart';

/// Generates a VS ARTS branded PDF Invoice matching the React screenshot design.
/// Uses PdfGoogleFonts (Noto Sans) so that symbols like rupees render correctly.
class PdfService {
  // ── Brand colours ─────────────────────────────────────────────────────────
  static const _darkGreen = PdfColor.fromInt(0xFF0D3B2E);
  static const _midGreen  = PdfColor.fromInt(0xFF1A5C45);
  static const _gold      = PdfColor.fromInt(0xFFE8A020);
  static const _goldLight = PdfColor.fromInt(0xFFFFD97D);
  static const _saffron   = PdfColor.fromInt(0xFFFF6B00);
  static const _bgFooter  = PdfColor.fromInt(0xFFF0F9F5);
  static const _bgRow1    = PdfColor.fromInt(0xFFF9FFFE);
  static const _bgRow2    = PdfColor.fromInt(0xFFEDF7F3);
  static const _text      = PdfColor.fromInt(0xFF1C2B24);
  static const _textMuted = PdfColor.fromInt(0xFF4A6B5C);
  static const _white     = PdfColors.white;
  static const _tableBorderColor = _goldLight;

  // Table Column Widths (in points)
  static const double _colWidthSNo   = 36;
  static const double _colWidthSize  = 65;
  static const double _colWidthQty   = 35;
  static const double _colWidthSqFt  = 55;
  static const double _colWidthRate  = 55;
  static const double _colWidthPrice = 70;

  // ─────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> generateInvoicePdf(InvoiceData data) async {
    // ── Load fonts that support ₹ ─────────────────────────────────────────
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold    = await PdfGoogleFonts.notoSansBold();
    final italic  = await PdfGoogleFonts.notoSansItalic();
    final icons   = await PdfGoogleFonts.materialIcons();

    // ── Load logo from assets ─────────────────────────────────────────────
    pw.ImageProvider? logoImage;
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null; // graceful fallback if asset missing
    }

    // ── Load signature from assets ────────────────────────────────────────
    pw.ImageProvider? signatureImage;
    try {
      final bytes = await rootBundle.load('assets/images/signature.png');
      signatureImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      signatureImage = null; // graceful fallback if asset missing
    }

    // ── Currency formatter with real ₹ symbol ─────────────────────────────
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9 ');

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: italic,
        icons: icons,
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) => _buildPage(ctx, data, logoImage, signatureImage, fmt),
      ),
    );

    return doc.save();
  }

  // ── Page layout ───────────────────────────────────────────────────────────
  static pw.Widget _buildPage(
    pw.Context ctx,
    InvoiceData data,
    pw.ImageProvider? logo,
    pw.ImageProvider? signature,
    NumberFormat fmt,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(0.8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _goldLight, width: 0.8),
        color: _white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildHeader(logo),
          _buildBillBar(data),
          _buildBillTo(data),
          _buildItemsTable(data, fmt),
          pw.SizedBox(height: 8),
          _buildTotalsSection(data, fmt),
          pw.Spacer(),
          _buildFooter(data, signatureImage: signature),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            _darkGreen,
            PdfColor.fromInt(0xFF165C43),
            PdfColor.fromInt(0xFF1E7A58),
          ],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: pw.Column(
        children: [
          // Top gradient divider line
          _buildHeaderDivider(),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              // Logo (circular border)
              if (logo != null) ...[
                pw.Container(
                  width: 76,
                  height: 76,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: _white,
                    border: pw.Border.all(color: _goldLight, width: 2.5),
                  ),
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.ClipOval(
                    child: pw.Image(logo),
                  ),
                ),
                pw.SizedBox(width: 18),
              ],
              // Company details
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // Est. 2000
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        _diamond(size: 5),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          'EST. 2000',
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 6.5,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(width: 5),
                        _diamond(size: 5),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    // Company Name
                    pw.Text(
                      'VS ARTS',
                      style: pw.TextStyle(
                        color: _white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 3.5,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    // Tagline
                    pw.Text(
                      'Flex & Banners',
                      style: pw.TextStyle(
                        color: _goldLight,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    // Center thin gold gradient divider
                    pw.Container(
                      width: 140,
                      height: 0.8,
                      decoration: const pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                          colors: [PdfColor.fromInt(0x00FFFFFF), _goldLight, PdfColor.fromInt(0x00FFFFFF)],
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    // Address
                    pw.Text(
                      'No. 01, Umpherson Street, Broadway, Chennai - 600108',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(color: PdfColor.fromInt(0xFFC8EADF), fontSize: 7.5),
                    ),
                    pw.SizedBox(height: 2),
                    // Phone / Email
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe0cd),
                          color: const PdfColor.fromInt(0xFFC8EADF),
                          size: 9,
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          '+91 93828 70862',
                          style: const pw.TextStyle(color: PdfColor.fromInt(0xFFC8EADF), fontSize: 7.5),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Text(
                          '|',
                          style: const pw.TextStyle(color: PdfColor.fromInt(0xFFC8EADF), fontSize: 7.5),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Icon(
                          const pw.IconData(0xe0be),
                          color: const PdfColor.fromInt(0xFFC8EADF),
                          size: 9,
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          'vsarts.69@gmail.com',
                          style: const pw.TextStyle(color: PdfColor.fromInt(0xFFC8EADF), fontSize: 7.5),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    // Founders
                    pw.RichText(
                      text: pw.TextSpan(
                        style: const pw.TextStyle(color: _goldLight, fontSize: 6.5),
                        children: [
                          const pw.TextSpan(text: 'Founder: '),
                          pw.TextSpan(text: 'Murugesan', style: pw.TextStyle(color: _white, fontWeight: pw.FontWeight.bold)),
                          const pw.TextSpan(text: '   \u2022   Managing Director: '),
                          pw.TextSpan(text: 'Srimukesh Murugesan', style: pw.TextStyle(color: _white, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Right side spacer to match alignment if logo exists
              if (logo != null) pw.SizedBox(width: 76 + 18),
            ],
          ),
          pw.SizedBox(height: 12),
          // Bottom gradient divider line
          _buildHeaderDivider(),
        ],
      ),
    );
  }

  static pw.Widget _buildHeaderDivider() {
    return pw.Container(
      height: 2.5,
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromInt(0x000D3B2E),
            _gold,
            _saffron,
            _gold,
            PdfColor.fromInt(0x001E7A58),
          ],
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(1.5)),
      ),
    );
  }

  // ── Bill No / Invoice / Date bar ─────────────────────────────────────────
  static pw.Widget _buildBillBar(InvoiceData data) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            _midGreen,
            PdfColor.fromInt(0xFF22755A),
          ],
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 9),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Bill No
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 8.5, letterSpacing: 0.5),
              children: [
                pw.TextSpan(text: 'BILL NO.  ', style: pw.TextStyle(color: _goldLight, fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(text: data.billNo, style: pw.TextStyle(color: _white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
          // Title
          pw.Row(
            children: [
              _diamond(size: 5),
              pw.SizedBox(width: 5),
              pw.Text(
                'INVOICE / BILL',
                style: pw.TextStyle(
                  color: _goldLight,
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(width: 5),
              _diamond(size: 5),
            ],
          ),
          // Date
          pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 8.5, letterSpacing: 0.5),
              children: [
                pw.TextSpan(text: 'DATE  ', style: pw.TextStyle(color: _goldLight, fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(
                  text: DateFormat('dd / MM / yyyy').format(data.date),
                  style: pw.TextStyle(color: _white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bill To section ───────────────────────────────────────────────────────
  static pw.Widget _buildBillTo(InvoiceData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFCFFFE),
        border: pw.Border(
          bottom: pw.BorderSide(color: _goldLight, width: 1.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _diamond(size: 4),
              pw.SizedBox(width: 4),
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(
                  color: _midGreen,
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _billToField('CLIENT NAME', data.clientName)),
              pw.SizedBox(width: 15),
              pw.Expanded(child: _billToField('ADDRESS', data.address)),
              pw.SizedBox(width: 15),
              pw.Expanded(child: _billToField('PHONE NO.', data.phoneNumber)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _billToField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: _textMuted,
            fontSize: 6,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _goldLight),
            ),
          ),
          child: pw.Text(
            value.isEmpty ? ' ' : value,
            style: pw.TextStyle(
              color: _text,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── Items table ───────────────────────────────────────────────────────────
  static pw.Widget _buildItemsTable(InvoiceData data, NumberFormat fmt) {
    // Format dimension nicely without trailing .0
    String formatDimension(double val) {
      if (val == val.toInt()) {
        return val.toInt().toString();
      }
      return val.toStringAsFixed(1);
    }

    String sizeText(InvoiceItem item) {
      final hasSize = item.length > 0 || item.breadth > 0;
      return hasSize
          ? '${formatDimension(item.length)} \u00d7 ${formatDimension(item.breadth)} ft'
          : '';
    }

    String sqFtText(InvoiceItem item) {
      return item.area > 0 ? (item.quantity * item.area).toStringAsFixed(2) : '';
    }

    final table = pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _tableBorderColor, width: 0.8),
        verticalInside: pw.BorderSide(color: _tableBorderColor, width: 0.8),
        left: pw.BorderSide(color: _tableBorderColor, width: 0.8),
        right: pw.BorderSide(color: _tableBorderColor, width: 0.8),
        top: pw.BorderSide(color: _tableBorderColor, width: 0.8),
        bottom: pw.BorderSide(color: _tableBorderColor, width: 0.8),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(_colWidthSNo),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(_colWidthSize),
        3: const pw.FixedColumnWidth(_colWidthQty),
        4: const pw.FixedColumnWidth(_colWidthSqFt),
        5: const pw.FixedColumnWidth(_colWidthRate),
        6: const pw.FixedColumnWidth(_colWidthPrice),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_darkGreen, _midGreen],
            ),
          ),
          children: [
            _thCell('S.No'),
            _thCell('Description of Work', alignment: pw.Alignment.centerLeft),
            _thCell('Size'),
            _thCell('Qty'),
            _thCell('Sq. Feet'),
            _thCell('Rate (\u20b9)'),
            _thCell('Price (\u20b9)', isLast: true),
          ],
        ),
        // Data Rows
        ...List.generate(data.items.length, (i) {
          final item = data.items[i];
          final isEven = i % 2 == 0;
          final rowBg = isEven ? _bgRow1 : _bgRow2;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _tbCell('${i + 1}', isBold: true, textColor: _midGreen),
              _tbCell(item.description, alignment: pw.Alignment.centerLeft),
              _tbCell(sizeText(item)),
              _tbCell('${item.quantity}'),
              _tbCell(sqFtText(item)),
              _tbCell(formatDimension(item.rate)),
              _tbCell(fmt.format(item.price), isBold: true, textColor: _darkGreen),
            ],
          );
        }),
      ],
    );

    // Transportation Charges Row attached directly below the table
    final transRow = pw.Container(
      height: 22,
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF8EC),
        border: pw.Border(
          left: pw.BorderSide(color: _tableBorderColor, width: 0.8),
          right: pw.BorderSide(color: _tableBorderColor, width: 0.8),
          bottom: pw.BorderSide(color: _tableBorderColor, width: 0.8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // S.No Spacing
          pw.Container(
            width: _colWidthSNo,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: _tableBorderColor, width: 0.8),
              ),
            ),
          ),
          // Transportation Label
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              alignment: pw.Alignment.centerLeft,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: _tableBorderColor, width: 0.8),
                ),
              ),
              child: pw.Text(
                'Transportation Charges',
                style: pw.TextStyle(
                  color: const PdfColor.fromInt(0xFF7A4F00),
                  fontWeight: pw.FontWeight.bold,
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 8,
                ),
              ),
            ),
          ),
          // Transportation Price Cell
          pw.Container(
            width: _colWidthPrice,
            alignment: pw.Alignment.center,
            child: pw.Text(
              fmt.format(data.locationOutsideParrys ? data.extraCharges : 0.0),
              style: pw.TextStyle(
                color: _darkGreen,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: pw.Column(
        children: [
          table,
          transRow,
        ],
      ),
    );
  }

  static pw.Widget _thCell(String text, {bool isLast = false, pw.Alignment alignment = pw.Alignment.center}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: isLast ? _goldLight : _white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tbCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.center,
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: textColor ?? _text,
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ── Totals section ────────────────────────────────────────────────────────
  static pw.Widget _buildTotalsSection(InvoiceData data, NumberFormat fmt) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 220,
            child: pw.Column(
              children: [
                // Sub Total row
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: _gold, width: 1.5),
                      bottom: pw.BorderSide(color: _goldLight, width: 0.8),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Sub Total', style: const pw.TextStyle(color: _textMuted, fontSize: 8)),
                      pw.Text(fmt.format(data.subTotal), style: pw.TextStyle(color: _text, fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                ),
                // Transportation Charges row
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: _goldLight, width: 0.8),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Transportation Charges', style: const pw.TextStyle(color: _textMuted, fontSize: 8)),
                      pw.Text(fmt.format(data.locationOutsideParrys ? data.extraCharges : 0.0), style: pw.TextStyle(color: _text, fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 3),
                // Grand Total box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [_darkGreen, _midGreen],
                    ),
                    border: pw.Border.all(color: _goldLight, width: 1.2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'GRAND TOTAL',
                        style: pw.TextStyle(
                          color: _goldLight,
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        fmt.format(data.grandTotal),
                        style: pw.TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(InvoiceData data, {pw.ImageProvider? signatureImage}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: const pw.BoxDecoration(
        color: _bgFooter,
        border: pw.Border(
          top: pw.BorderSide(color: _goldLight, width: 3),
        ),
      ),
      child: pw.Column(
        children: [
          // Amount in Words
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _white,
              border: pw.Border.all(color: _goldLight),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.RichText(
              text: pw.TextSpan(
                style: const pw.TextStyle(fontSize: 7.5),
                children: [
                  pw.TextSpan(
                    text: 'AMOUNT IN WORDS:  ',
                    style: pw.TextStyle(color: _midGreen, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
                  ),
                  pw.TextSpan(
                    text: NumberToWords.convert(data.grandTotal),
                    style: pw.TextStyle(color: _darkGreen, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          // Note
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF8E8),
              border: pw.Border.all(color: _goldLight),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Custom warning icon
                pw.Container(
                  width: 11,
                  height: 11,
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF7A4F00),
                    shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text('!', style: pw.TextStyle(color: _white, fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(
                      style: pw.TextStyle(color: PdfColor.fromInt(0xFF7A4F00), fontSize: 7.5),
                      children: [
                        pw.TextSpan(text: 'Note: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.TextSpan(text: 'If the shop location is out from Parrys, extra charges will be applicable.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          // Signatures Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      color: _midGreen,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'For queries: +91 93828 70862',
                    style: const pw.TextStyle(color: _textMuted, fontSize: 7.5),
                  ),
                ],
              ),
              _signatureBlock('Customer Signature', 'Name & Date'),
              _signatureBlock('Srimukesh Murugesan', 'Managing Director, VS Arts', signatureImage: signatureImage),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(String name, String role, {pw.ImageProvider? signatureImage}) {
    return pw.Column(
      children: [
        pw.Container(
          width: 110,
          height: 36,
          alignment: pw.Alignment.bottomCenter,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _darkGreen, width: 1.2),
            ),
          ),
          child: signatureImage != null
              ? pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Image(signatureImage, height: 34, fit: pw.BoxFit.contain),
                )
              : null,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          name,
          style: pw.TextStyle(
            color: _darkGreen,
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          role,
          style: const pw.TextStyle(color: _textMuted, fontSize: 6.5),
        ),
      ],
    );
  }

  // ── Diamond accent (geometry — no font encoding needed) ───────────────────
  static pw.Widget _diamond({double size = 6}) {
    return pw.Transform.rotate(
      angle: 0.785398,
      child: pw.Container(
        width: size * 0.65,
        height: size * 0.65,
        color: _goldLight,
      ),
    );
  }
}
