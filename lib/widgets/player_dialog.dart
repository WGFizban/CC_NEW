import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import 'meeple_icon.dart';

/// Wynik dialogu dodawania/edycji gracza.
class PlayerFormResult {
  final String name;
  final Color color;
  final bool delete;

  const PlayerFormResult.save(this.name, this.color) : delete = false;
  const PlayerFormResult.delete()
    : name = '',
      color = Colors.transparent,
      delete = true;
}

/// Dialog dodawania ([player] == null) lub edycji gracza.
///
/// [availableColors] to kolory z [kPlayerColors] niezajęte przez innych graczy.
Future<PlayerFormResult?> showPlayerDialog(
  BuildContext context, {
  required List<Color> availableColors,
  Player? player,
}) {
  return showDialog<PlayerFormResult>(
    context: context,
    builder: (_) =>
        _PlayerDialog(availableColors: availableColors, player: player),
  );
}

class _PlayerDialog extends StatefulWidget {
  final List<Color> availableColors;
  final Player? player;

  const _PlayerDialog({required this.availableColors, this.player});

  @override
  State<_PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<_PlayerDialog> {
  late final TextEditingController _nameController;
  late Color _color;
  bool _showError = false;

  bool get _isEditing => widget.player != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player?.name ?? '');
    _color =
        widget.player?.color ??
        (widget.availableColors.isNotEmpty
            ? widget.availableColors.first
            : Colors.grey);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Kolory do wyboru: własny kolor edytowanego gracza (jeśli spoza listy
  /// podstawowej) oraz wszystkie wolne kolory podstawowe.
  List<Color> get _options {
    final current = widget.player?.color;
    return [
      if (current != null && !kPlayerColors.contains(current)) current,
      for (final c in kPlayerColors)
        if (c == current || widget.availableColors.contains(c)) c,
    ];
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, PlayerFormResult.save(name, _color));
  }

  Future<void> _pickCustomColor() async {
    Color temp = _color;
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wybierz kolor z palety'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            enableAlpha: false,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, temp),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _color = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edytuj gracza' : 'Dodaj gracza'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Imię',
                errorText: _showError ? 'Podaj imię gracza' : null,
              ),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            Text(_isEditing ? 'Zmień kolor:' : 'Wybierz kolor:'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                for (final c in _options)
                  _ColorSwatch(
                    color: c,
                    selected: _color == c,
                    onTap: () => setState(() => _color = c),
                  ),
                _ColorSwatch(
                  color: _color,
                  selected: true,
                  onTap: _pickCustomColor,
                  child: Icon(
                    Icons.palette,
                    size: 16,
                    color: foregroundOn(_color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              color: kBrandColor,
              child: MeepleIcon(color: _color, size: 60),
            ),
          ],
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const PlayerFormResult.delete()),
            child: const Text('Usuń gracza'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Zapisz' : 'Dodaj'),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selected ? Colors.black : Colors.grey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}
