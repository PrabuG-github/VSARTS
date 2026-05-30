import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Model carrying the submitted form data.
class FormData {
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String message;
  final DateTime date;
  final DateTime submittedAt;

  const FormData({
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.message,
    required this.date,
    required this.submittedAt,
  });
}

/// Generates a styled PDF from a [FormData] object.
class PdfService {
  // Brand colours (approximated in PdfColor)
  static const _primary = PdfColor.fromInt(0xFF6366F1);   // Indigo 500
  static const _secondary = PdfColor.fromInt(0xFFEC4899); // Pink 500
  static const _bgLight = PdfColor.fromInt(0xFFF8FAFC);
  static const _textDark = PdfColor.fromInt(0xFF0F172A);
  static const _textMuted = PdfColor.fromInt(0xFF475569);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _success = PdfColor.fromInt(0xFF10B981);

  static Future<Uint8List> generateFormPdf(FormData data) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // ─── Background ──────────────────────────────────
              pw.Positioned.fill(
                child: pw.Container(color: _bgLight),
              ),

              // ─── Top gradient banner ──────────────────────────
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: pw.Container(
                  height: 160,
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

              // ─── Main Content ─────────────────────────────────
              pw.Positioned.fill(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 48),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 36),

                      // Header area (inside banner)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'VSARTS Studio',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Submission Report',
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius:
                                      pw.BorderRadius.all(pw.Radius.circular(20)),
                                ),
                                child: pw.Text(
                                  'SUBMITTED',
                                  style: pw.TextStyle(
                                    color: _success,
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                DateFormat('dd MMM yyyy').format(data.submittedAt),
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 11,
                                ),
                              ),
                              pw.Text(
                                DateFormat('HH:mm').format(data.submittedAt),
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 48),

                      // ─── White content card ───────────────────
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(32),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(16)),
                            border: pw.Border.all(color: _border),
                            boxShadow: const [
                              pw.BoxShadow(
                                color: PdfColor.fromInt(0x14000000),
                                blurRadius: 16,
                                offset: PdfPoint(0, 4),
                              ),
                            ],
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _sectionHeading('Personal Information'),
                              pw.SizedBox(height: 16),
                              _rowGroup([
                                _infoField('Full Name', data.name),
                                _infoField('Email Address', data.email),
                              ]),
                              pw.SizedBox(height: 12),
                              _infoField('Phone Number', data.phone),

                              pw.SizedBox(height: 24),
                              _divider(),
                              pw.SizedBox(height: 24),

                              _sectionHeading('Request Details'),
                              pw.SizedBox(height: 16),
                              _rowGroup([
                                _infoField('Subject', data.subject),
                                _infoField(
                                  'Preferred Date',
                                  DateFormat('dd MMM yyyy').format(data.date),
                                ),
                              ]),
                              pw.SizedBox(height: 12),
                              _messageField('Message', data.message),

                              pw.Spacer(),

                              // Footer line
                              _divider(),
                              pw.SizedBox(height: 12),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Generated by VSARTS Studio',
                                    style: const pw.TextStyle(
                                      color: _textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                  pw.Text(
                                    'Ref: ${DateFormat('yyyyMMddHHmmss').format(data.submittedAt)}',
                                    style: const pw.TextStyle(
                                      color: _textMuted,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 20),
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

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static pw.Widget _sectionHeading(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 18,
          decoration: const pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            color: _primary,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoField(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _bgLight,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: _border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                color: _textMuted,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value.isEmpty ? '—' : value,
              style: pw.TextStyle(
                color: _textDark,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _messageField(String label, String value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              color: _textMuted,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value.isEmpty ? '—' : value,
            style: const pw.TextStyle(
              color: _textDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rowGroup(List<pw.Widget> children) {
    return pw.Row(
      children: _interleave(children, pw.SizedBox(width: 12)),
    );
  }

  static pw.Widget _divider() {
    return pw.Divider(color: _border, thickness: 1);
  }

  static List<pw.Widget> _interleave(List<pw.Widget> items, pw.Widget sep) {
    final result = <pw.Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(sep);
    }
    return result;
  }
}
