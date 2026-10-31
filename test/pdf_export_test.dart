import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cc_new/l10n/app_localizations_pl.dart';
import 'package:cc_new/models/expansion.dart';
import 'package:cc_new/models/player.dart';
import 'package:cc_new/models/summary_table.dart';
import 'package:cc_new/services/pdf_export.dart';

// Jednopikselowy PNG (do strony ze zdjęciem planszy).
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

Player _p(String name, int points, int color) =>
    Player(name: name, color: Color(color))..points = points;

Future<Uint8List> _build({Uint8List? photo}) {
  final l = AppLocalizationsPl();
  final players = [
    _p('Bob', 5, 0xFF1D27EA),
    _p('Ala', 10, 0xFFE53935),
  ];
  final table = SummaryTable.build(
    l: l,
    players: players,
    log: const [],
    expansions: {Expansion.tradersBuilders},
  );
  return buildSummaryPdf(
    l: l,
    table: table,
    expansions: {Expansion.tradersBuilders},
    elapsed: const Duration(hours: 1, minutes: 5, seconds: 9),
    date: DateTime(2026, 10, 31, 20, 15),
    photo: photo,
    regularFont: File('assets/fonts/DejaVuSans.ttf').readAsBytesSync(),
    boldFont: File('assets/fonts/DejaVuSans-Bold.ttf').readAsBytesSync(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nazwa pliku i format czasu gry', () {
    expect(
      pdfFileName(DateTime(2026, 10, 31, 20, 5)),
      'carcassonne_2026-10-31_20-05.pdf',
    );
    expect(formatGameDuration(const Duration(hours: 1, minutes: 5, seconds: 9)),
        '01:05:09');
  });

  test('tabela podsumowania: zwycięzca na górze, ostatnia kolumna to wynik', () {
    final l = AppLocalizationsPl();
    final table = SummaryTable.build(
      l: l,
      players: [_p('Bob', 5, 0xFF1D27EA), _p('Ala', 10, 0xFFE53935)],
      log: const [],
      expansions: const {},
    );
    expect([for (final r in table.rows) r.player.name], ['Ala', 'Bob']);
    expect(table.columns.last.title, l.colTotal);
    expect([for (final r in table.rows) r.total], [10, 5]);
    expect(table.best(table.columns.length - 1), 10);
  });

  test('PDF z podsumowaniem to poprawny dokument PDF', () async {
    final bytes = await _build();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('zdjęcie planszy dodaje kolejną stronę', () async {
    final without = await _build();
    final withPhoto = await _build(photo: _png);
    expect(String.fromCharCodes(withPhoto.take(5)), '%PDF-');
    expect(withPhoto.length, greaterThan(without.length));
  });
}
