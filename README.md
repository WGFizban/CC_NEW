# CarcassonneCounter (cc_new)

Aplikacja we Flutterze do liczenia punktów w grze planszowej Carcassonne,
z obsługą wybranych dodatków.

## Funkcje

- lista graczy z pionkami w wybranych kolorach, posortowana wg wyniku na bieżąco,
- punkty za miasto, drogę, klasztor, pola i wróżkę (z katedrą, karczmą, świnką
  oraz obiektami nieukończonymi),
- cofanie ostatniego zatwierdzenia (także tych dotyczących wielu graczy),
- stoper czasu gry,
- zapis graczy, punktów, surowców i ustawień w pamięci urządzenia.

Kliknięcie gracza otwiera wybór rodzaju punktacji, a przytrzymanie – edycję
lub usunięcie. Dodatki włączasz w menu (**Dodatki…**); domyślnie są włączone
wszystkie.

## Obsługiwane dodatki

### Kupcy i budowniczowie
- W punktacji miasta liczniki **wina, żyta i sukna** – surowce dostaje gracz,
  który domknął miasto (nawet bez ludka w mieście).
- Osobny kafelek **Surowce** do ręcznego dopisania żetonów.
- Liczniki pilnują limitów z gry: 9 wina, 6 żyta i 5 sukna (razem 20 żetonów).
- **Premia 10 pkt** dla prowadzącego w każdym rodzaju surowca liczona na
  bieżąco: przy remisie każdy z remisujących dostaje pełne 10, a przy zerze
  nikt. Wynik na liście to punkty z planszy + premia (np. `35 + 10`),
  a nad listą jest tabela prowadzących.
- Świnka na polu: miasta po 4 pkt zamiast 3.

### Mosty, zamki i bazary
- **Mosty** punktują jak płytki z drogą: płytkę z mostem liczysz raz, więc
  w osobnym liczniku wpisz tylko te płytki, których nie ma jeszcze w „Płytkach".
- **Zamki** na polach są warte 4 pkt zamiast 3 (ze świnką 5).
- Kafelek **Zamek**: punkty równe punktom ukończonej sąsiedniej budowli.
- Kafelek **Bazar**: rozliczenie licytacji – kupno od najwyżej licytującego,
  sprzedaż jemu albo zapłata, gdy licytował tylko wybierający. Wynik może
  spaść poniżej zera.

### Cyrk objazdowy
- **Cyrk**: wybierasz odkryty żeton zwierzęcia (słoń 7, lew 6, niedźwiedź 5,
  foka 4, małpka 3, pchła 1) i wpisujesz, ile ludków ma każdy gracz na płytce
  cyrku i ośmiu sąsiednich. Aplikacja pilnuje zapasu żetonów (16 sztuk).
- **Akrobaci**: ukończona piramida (3 ludki, każdy akrobata 5 pkt) oraz
  punktacja końcowa (5 pkt za każdego akrobatę na planszy).
- **Dyrektor cyrku**: 2 pkt za każdą płytkę cyrku lub akrobatów wokół niego,
  jako opcja przy mieście, drodze, klasztorze i polach albo osobny kafelek.

### Wzgórza i owce
- **Winnice**: przy ukończonym klasztorze 3 pkt za każdą winnicę (do 8).
- **Owce**: stado składa się z żetonów 1–4 owce w limitach z gry
  (4×1, 5×2, 5×3, 2×4), czyli najwyżej 37 owiec. Można wskazać kilku
  pasterzy w jednym polu – każdy dostaje punkty za całe stado.

## Struktura `lib/`

| Katalog | Zawartość |
|---|---|
| `models/` | gracz, reguły punktacji, surowce, cyrk, owce, zdarzenia punktowe |
| `services/` | zapis graczy i ustawień (`shared_preferences`) |
| `screens/` | lista graczy, wybór punktacji i osobne ekrany dodatków |
| `widgets/` | pionek, liczniki, klawiatura, piramida, widżety surowców |
| `theme/` | kolory aplikacji i graczy |

## Uruchomienie

```bash
flutter pub get
flutter run
flutter test
```
