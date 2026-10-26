import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/l10n.dart';
import '../models/app_version.dart';

/// Autor aplikacji (pokazywany na ekranie „Info o aplikacji").
const String kAuthorName = 'WGFizban';

/// Informacje o aplikacji: krótki opis, wersja, autor, nota o prawach
/// i licencje użytych bibliotek.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<String> _version() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return formatAppVersion(info.version);
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/icons/splash_logo.png', width: 160),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'CarcassonneCounter',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FutureBuilder<String>(
            future: _version(),
            builder: (context, snapshot) => Text(
              l.aboutVersion(snapshot.data ?? '…'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.aboutDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 24),
          Text(
            l.aboutMadeBy(kAuthorName),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text(
            l.aboutDisclaimer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'CarcassonneCounter',
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(l.aboutLicenses),
          ),
        ],
      ),
    );
  }
}
