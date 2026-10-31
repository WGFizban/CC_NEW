import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../models/summary_table.dart';

const String _regularFontAsset = 'assets/fonts/DejaVuSans.ttf';
const String _boldFontAsset = 'assets/fonts/DejaVuSans-Bold.ttf';

/// Nazwa pliku z PDF-em gry, np. `carcassonne_2026-10-31_20-15.pdf`.
String pdfFileName(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'carcassonne_${time.year}-${two(time.month)}-${two(time.day)}_'
      '${two(time.hour)}-${two(time.minute)}.pdf';
}

/// Czas gry jako `gg:mm:ss`.
String formatGameDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:'
      '${two(d.inSeconds.remainder(60))}';
}

String _formatDate(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
}

/// Buduje PDF z podsumowaniem gry: tabela punktów, zwycięzca, dodatki, data
/// i czas gry. Gdy podano [photo] (JPEG/PNG), dodaje je jako ostatnią stronę.
///
/// Czcionki (z polskimi znakami) pochodzą z zasobów aplikacji; w testach
/// można je podać bezpośrednio w [regularFont] i [boldFont].
Future<Uint8List> buildSummaryPdf({
  required AppLocalizations l,
  required SummaryTable table,
  required Set<Expansion> expansions,
  required Duration elapsed,
  required DateTime date,
  Uint8List? photo,
  Uint8List? regularFont,
  Uint8List? boldFont,
}) async {
  final regular = pw.Font.ttf(
    regularFont == null
        ? await rootBundle.load(_regularFontAsset)
        : ByteData.sublistView(regularFont),
  );
  final bold = pw.Font.ttf(
    boldFont == null
        ? await rootBundle.load(_boldFontAsset)
        : ByteData.sublistView(boldFont),
  );
  final theme = pw.ThemeData.withFont(base: regular, bold: bold);

  final enabled = [
    for (final e in Expansion.values)
      if (expansions.contains(e)) e.title(l),
  ];
  final expansionsText = l.pdfExpansions(
    enabled.isEmpty ? l.noneCap : enabled.join(', '),
  );

  final best = table.rows.isEmpty ? 0 : table.rows.first.total;
  final winners = [
    for (final r in table.rows)
      if (r.total == best) r.player.name,
  ];
  final winnerText = table.rows.isEmpty
      ? null
      : '${winners.length == 1 ? l.winner : l.tiedLead}: '
            '${winners.join(', ')} – ${l.pointsValue(best)}';

  final doc = pw.Document(title: l.summaryTitle, theme: theme);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Text(
          'Carcassonne – ${l.summaryTitle}',
          style: pw.TextStyle(font: bold, fontSize: 22),
        ),
        pw.SizedBox(height: 6),
        pw.Text(l.pdfDate(_formatDate(date)), style: const pw.TextStyle(fontSize: 11)),
        pw.Text(expansionsText, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(
          l.gameTime(formatGameDuration(elapsed)),
          style: const pw.TextStyle(fontSize: 11),
        ),
        if (winnerText != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(winnerText, style: pw.TextStyle(font: bold, fontSize: 14)),
        ],
        pw.SizedBox(height: 14),
        _table(l, table, bold),
      ],
    ),
  );

  if (photo != null) {
    final size = await _imageSize(photo);
    final landscape = size == null || size.$1 >= size.$2;
    final image = pw.MemoryImage(photo);
    doc.addPage(
      pw.Page(
        pageFormat: landscape
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4.portrait,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              l.pdfBoardPage,
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
            pw.SizedBox(height: 8),
            pw.Expanded(
              child: pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return doc.save();
}

/// Wymiary zdjęcia (szerokość, wysokość) albo `null`, gdy nie da się ich
/// odczytać.
Future<(int, int)?> _imageSize(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = (frame.image.width, frame.image.height);
    frame.image.dispose();
    codec.dispose();
    return size;
  } catch (_) {
    return null;
  }
}

PdfColor _tint(int argb, double amount) {
  // Rozjaśnienie koloru gracza ku bieli, żeby tekst w wierszu był czytelny.
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  double mix(int c) => (c + (255 - c) * amount) / 255;
  return PdfColor(mix(r), mix(g), mix(b));
}

pw.Widget _table(AppLocalizations l, SummaryTable table, pw.Font bold) {
  final columnCount = table.columns.length;
  final fontSize = columnCount > 14 ? 7.5 : (columnCount > 9 ? 9.0 : 11.0);

  pw.Widget cell(
    String text, {
    bool isBold = false,
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align == pw.Alignment.centerLeft
            ? pw.TextAlign.left
            : pw.TextAlign.center,
        style: pw.TextStyle(
          font: isBold ? bold : null,
          fontSize: fontSize,
        ),
      ),
    );
  }

  final header = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
    children: [
      cell(l.colPlayer, isBold: true, align: pw.Alignment.centerLeft),
      for (final c in table.columns) cell(c.title, isBold: true),
    ],
  );

  final body = [
    for (final row in table.rows)
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: _tint(row.player.color.toARGB32(), 0.72),
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 9,
                  height: 9,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(row.player.color.toARGB32()),
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.grey800, width: 0.6),
                  ),
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(
                  child: pw.Text(
                    row.player.name,
                    style: pw.TextStyle(font: bold, fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < columnCount; i++)
            cell(
              row.values[i] == 0 && i != columnCount - 1
                  ? '–'
                  : '${row.values[i]}',
              isBold: i == columnCount - 1,
            ),
        ],
      ),
  ];

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      for (var i = 1; i <= columnCount; i++) i: const pw.FlexColumnWidth(1.4),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [header, ...body],
  );
}
