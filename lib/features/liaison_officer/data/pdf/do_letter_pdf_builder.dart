import 'dart:typed_data';

import 'package:liaison_officer/features/liaison_officer/data/models/cap/cap_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Client-side DO letter PDF when CAP returns empty preview bytes.
///
/// Does not merge AcroForm fields of an uploaded template PDF — that requires
/// CAP. Builds a filled letter from organisation + template metadata.
class DoLetterPdfBuilder {
  DoLetterPdfBuilder._();

  static Future<Uint8List> build({
    required LoOrganisationDto org,
    DoLetterTemplateDto? template,
  }) async {
    final doc = pw.Document();
    final authority = template?.signingAuthority.trim().isNotEmpty == true
        ? template!.signingAuthority
        : 'Signing Authority';
    final templateName = template?.templateName.trim().isNotEmpty == true
        ? template!.templateName
        : 'DO Letter';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              templateName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Demarcation Order / Nomination Request'),
            pw.SizedBox(height: 24),
            pw.Text('To,'),
            pw.SizedBox(height: 8),
            pw.Text(org.headName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(org.headDesignation),
            pw.Text(org.orgName,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (org.address != null && org.address!.trim().isNotEmpty)
              pw.Text(org.address!),
            pw.SizedBox(height: 24),
            pw.Text(
              'Subject: Request to nominate Liaison Officers for Aero India',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Organisation Type: ${org.orgTypeName ?? '—'}',
            ),
            pw.Text('Primary Email: ${org.primaryEmail}'),
            pw.Text('Primary Contact: ${org.primaryContact}'),
            pw.SizedBox(height: 16),
            pw.Text(
              'You are requested to nominate Liaison Officers for the forthcoming '
              'Aero India event and complete LO profiles through the Committee '
              'Automation Portal.',
            ),
            pw.SizedBox(height: 32),
            pw.Text('Yours sincerely,'),
            pw.SizedBox(height: 24),
            pw.Text(authority,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('LO Committee'),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
