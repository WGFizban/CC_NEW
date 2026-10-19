# CarcassonneCounter (cc_new)

Aplikacja we Flutterze do liczenia punktów w grze planszowej Carcassonne.

## Funkcje

- lista graczy z pionkami w wybranych kolorach, posortowana wg punktów,
- dodawanie punktów za miasto, drogę, klasztor, pola, wróżkę i owce
  (z katedrą, karczmą i świnką oraz obiektami nieukończonymi),
- cofanie ostatnio dodanych punktów,
- stoper czasu gry,
- zapis graczy i punktów w pamięci urządzenia.

Kliknięcie gracza otwiera dodawanie punktów, a przytrzymanie – edycję lub usunięcie.

## Struktura `lib/`

| Katalog | Zawartość |
|---|---|
| `models/` | `Player` oraz reguły punktacji (`calculatePoints`) |
| `services/` | zapis graczy (`shared_preferences`) |
| `screens/` | ekran graczy, wybór rodzaju punktacji, liczenie punktów |
| `widgets/` | pionek (`MeepleIcon`), dialog dodawania/edycji gracza |
| `theme/` | kolory aplikacji i graczy |

## Uruchomienie

```bash
flutter pub get
flutter run
flutter test
```
