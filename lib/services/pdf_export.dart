import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../l10n/labels.dart';
import '../models/expansion.dart';
import '../models/summary_table.dart';
import '../widgets/goods_widgets.dart' show GoodsStyle;

const String _regularFontAsset = 'assets/fonts/DejaVuSans.ttf';
const String _boldFontAsset = 'assets/fonts/DejaVuSans-Bold.ttf';
const String _meepleAsset = 'assets/icons/meeple.svg';

/// Odczyt SVG z zasobów (w testach można podstawić odczyt z plików).
typedef SvgLoader = Future<String> Function(String asset);

/// Fiolet wyróżnienia najlepszych wyników (jak w aplikacji).
const PdfColor _accent = PdfColor.fromInt(0xFF6750A4);

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
  SvgLoader? loadSvg,
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

  // Ikony kolumn i mepel: gdy któregoś SVG nie da się wczytać, w tabeli
  // zostaje sam tekst albo kolorowe kółko.
  final load = loadSvg ?? rootBundle.loadString;
  Future<String?> tryLoad(String asset) async {
    try {
      return await load(asset);
    } catch (_) {
      return null;
    }
  }

  final iconSvgs = <String, String>{};
  for (final c in table.columns) {
    final asset = c.type?.iconAsset ?? c.goods?.iconAsset;
    if (asset == null || iconSvgs.containsKey(asset)) continue;
    final svg = await tryLoad(asset);
    if (svg != null) iconSvgs[asset] = svg;
  }
  final meepleSvg = await tryLoad(_meepleAsset);

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
        _table(l, table, bold, iconSvgs, meepleSvg),
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

/// SVG jako widżet PDF albo `null`, gdy nie da się go sparsować.
pw.Widget? _svg(String? svg, double size) {
  if (svg == null) return null;
  try {
    return pw.SvgImage(svg: svg, width: size, height: size);
  } catch (_) {
    return null;
  }
}

/// Mepel w kolorze gracza (z obrysem kontrastowym jak w aplikacji) albo
/// `null`, gdy nie da się go narysować.
pw.Widget? _meeple(String? svg, int argb, double size) {
  if (svg == null) return null;
  String hex(int c) => '#${(c & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  final luminance = ui.Color(argb).computeLuminance();
  final outline = luminance > 0.18 ? '#000000' : '#FFFFFF';
  final colored = svg
      .replaceFirst('fill="#FF0000"', 'fill="${hex(argb)}"')
      .replaceFirst('stroke="black"', 'stroke="$outline"');
  return _svg(colored, size);
}

pw.Widget _table(
  AppLocalizations l,
  SummaryTable table,
  pw.Font bold,
  Map<String, String> iconSvgs,
  String? meepleSvg,
) {
  final columnCount = table.columns.length;
  final fontSize = columnCount > 14 ? 7.5 : (columnCount > 9 ? 9.0 : 11.0);
  final iconSize = columnCount > 14 ? 16.0 : 20.0;
  final best = [for (var i = 0; i < columnCount; i++) table.best(i)];

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
        style: pw.TextStyle(font: isBold ? bold : null, fontSize: fontSize),
      ),
    );
  }

  pw.Widget headerCell(SummaryColumn c) {
    final asset = c.type?.iconAsset ?? c.goods?.iconAsset;
    final icon = asset == null ? null : _svg(iconSvgs[asset], iconSize);
    if (icon == null) return cell(c.title, isBold: true);
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      // Sama ikona, bez podpisu: tak jak w aplikacji (podpisy się zawijały).
      child: icon,
    );
  }

  // Najlepszy (niezerowy) wynik w kolumnie: pogrubiona biała cyfra na
  // fioletowej pastylce, jak na ekranie podsumowania.
  pw.Widget valueCell(int v, int column) {
    final isTotal = column == columnCount - 1;
    final top = v > 0 && v == best[column];
    final text = v == 0 && !isTotal ? '–' : '$v';
    if (!top) return cell(text, isBold: isTotal);
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: pw.BoxDecoration(
          color: _accent,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: bold,
            fontSize: fontSize,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  final header = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
    children: [
      cell(l.colPlayer, isBold: true, align: pw.Alignment.centerLeft),
      for (final c in table.columns) headerCell(c),
    ],
  );

  pw.Widget playerMark(int argb) {
    final meeple = _meeple(meepleSvg, argb, 16);
    if (meeple != null) return pw.SizedBox(width: 16, height: 16, child: meeple);
    return pw.Container(
      width: 10,
      height: 10,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(argb),
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: PdfColors.grey800, width: 0.6),
      ),
    );
  }

  final body = [
    for (final row in table.rows)
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: _tint(row.player.color.toARGB32(), 0.72),
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: pw.Row(
              children: [
                playerMark(row.player.color.toARGB32()),
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
          for (var i = 0; i < columnCount; i++) valueCell(row.values[i], i),
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
