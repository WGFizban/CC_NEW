import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n.dart';
import '../models/expansion.dart';
import '../models/history_entry.dart';
import '../models/player.dart';
import '../models/summary_table.dart';
import '../services/pdf_export.dart';
import '../widgets/game_icon.dart';
import '../widgets/goods_widgets.dart';
import '../widgets/info_hint.dart';
import '../widgets/meeple_icon.dart';

/// Podsumowanie gry: tabela punktów każdego gracza według rodzaju punktacji
/// (kolejność: zwycięzca na górze) i czas gry pod tabelą.
class SummaryScreen extends StatelessWidget {
  final List<Player> players;
  final List<HistoryEntry> log;
  final Set<Expansion> expansions;
  final Duration elapsed;

  const SummaryScreen({
    super.key,
    required this.players,
    required this.log,
    required this.expansions,
    required this.elapsed,
  });

  static String _duration(Duration d) => formatGameDuration(d);

  /// „Zapisz PDF z gry”: pyta o zdjęcie planszy (aparat), buduje dokument
  /// z podsumowaniem i zapisuje go w wybranym przez użytkownika miejscu.
  Future<void> _savePdf(BuildContext context, SummaryTable table) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final addPhoto = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pdfPhotoTitle),
        content: Text(l.pdfPhotoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.pdfNoPhoto),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.pdfAddPhoto),
          ),
        ],
      ),
    );
    // Zamknięcie okna poza przyciskami oznacza rezygnację z zapisu.
    if (addPhoto == null || !context.mounted) return;

    Uint8List? photo;
    if (addPhoto) {
      try {
        final shot = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 85,
        );
        if (shot == null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l.pdfNoPhotoTaken)));
          return;
        }
        photo = await shot.readAsBytes();
      } catch (_) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.pdfCameraError)));
        return;
      }
    }

    try {
      final now = DateTime.now();
      final bytes = await buildSummaryPdf(
        l: l,
        table: table,
        expansions: expansions,
        elapsed: elapsed,
        date: now,
        photo: photo,
      );
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: l.savePdf,
        fileName: pdfFileName(now),
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      // Na przeglądarce plik jest pobierany i ścieżka nie jest znana.
      if (saved != null || kIsWeb) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l.pdfSaved)));
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.pdfSaveError)));
    }
  }

  Widget _header(String asset, String name) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => showHintBubble(ctx, message: name),
        child: GameIcon(asset, size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final table = SummaryTable.build(
      l: l,
      players: players,
      log: log,
      expansions: expansions,
    );
    final columnCount = table.columns.length;
    final best = [for (var i = 0; i < columnCount; i++) table.best(i)];
    final accent = Theme.of(context).colorScheme.primary;

    DataCell num(int v, int column, {bool bold = false}) {
      final top = v > 0 && v == best[column];
      return DataCell(
        Center(
          child: top
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  v == 0 ? '–' : '$v',
                  style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
                ),
        ),
      );
    }

    DataColumn column(SummaryColumn c) {
      final icon = c.type?.iconAsset ?? c.goods?.iconAsset;
      return DataColumn(
        label: icon == null ? Text(c.title) : _header(icon, c.title),
      );
    }

    final rows = [
      for (final row in table.rows)
        DataRow(
          color: WidgetStatePropertyAll(
            row.player.color.withValues(alpha: 0.22),
          ),
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MeepleIcon(color: row.player.color, size: 26),
                  const SizedBox(width: 6),
                  Text(
                    row.player.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < columnCount; i++)
              num(row.values[i], i, bold: i == columnCount - 1),
          ],
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.summaryTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 12,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columns: [
                DataColumn(label: Text(l.colPlayer)),
                for (final c in table.columns) column(c),
              ],
              rows: rows,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.gameTime(_duration(elapsed)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => _savePdf(context, table),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l.savePdf),
            ),
          ),
        ],
      ),
    );
  }
}
