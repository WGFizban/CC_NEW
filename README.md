# CarcassonneCounter (cc_new)

Aplikacja we Flutterze do liczenia punktów w grze planszowej Carcassonne,
z obsługą wybranych dodatków.

## Funkcje

- lista graczy z pionkami w wybranych kolorach, posortowana wg wyniku na bieżąco,
- punkty za miasto, drogę, klasztor i pola (z katedrą, karczmą, świnką
  oraz obiektami nieukończonymi),
- klawiatura numeryczna wysuwana od dołu (po wejściu na ekran i po stuknięciu
  w pole), zwijana przyciskiem w rogu lub stuknięciem w puste miejsce,
- zatwierdzanie punktów dużą zieloną fajką w prawym górnym rogu ekranu,
- małe podpowiedzi „?" zamiast długich opisów (dotknięcie na telefonie,
  najechanie myszą na komputerze),
- **punkty wspólne** w mieście, drodze, klasztorze i polach: zwijana sekcja,
  w której wskazujesz graczy dostających te same punkty (remis o większość),
- wybór rodzaju punktacji w siatce pogrupowanej według dodatków,
- cofanie ostatniego zatwierdzenia (także tych dotyczących wielu graczy),
- **historia punktów** jako tabela (menu → Historia punktów),
- **Zakończ grę** (menu): zwycięzca, ranking i rozbicie punktów według rodzaju
  punktacji, z opcją nowej gry,
- stoper czasu gry,
- zapis graczy, punktów, surowców i ustawień w pamięci urządzenia,
- ustawienia: nie wygaszaj ekranu podczas gry (domyślnie włączone),
  wybór dodatków. Historia punktów jest zapamiętywana między uruchomieniami
  (ostatnie 500 wpisów; cofnięcie usuwa też wpis, „Resetuj punkty" czyści),
- jeden spójny zestaw ikon (`assets/icons/game/`).

Kliknięcie gracza otwiera wybór rodzaju punktacji, a przytrzymanie – edycję
lub usunięcie. Dodatki włączasz w menu (**Ustawienia…**); domyślnie są włączone
wszystkie.

## Obsługiwane dodatki

### Karczmy i katedry
- Opcje **Katedra** (miasto: 3 pkt za płytkę i sztandar) i **Karczma**
  (droga: 2 pkt za płytkę) są dostępne tylko przy włączonym dodatku.
- Nieukończona budowla z katedrą lub karczmą nie daje punktów, więc nie ma
  osobnej opcji „nieukończone" – po prostu niczego się nie dopisuje.

### Kupcy i budowniczowie
- W punktacji miasta liczniki **wina, żyta i sukna** – surowce dostaje gracz,
  który domknął miasto (nawet bez ludka w mieście).
- Osobny kafelek **Surowce** do ręcznego dopisania żetonów.
- Liczniki pilnują limitów z gry: 9 wina, 6 żyta i 5 sukna (razem 20 żetonów).
- **Premia 10 pkt** dla prowadzącego w każdym rodzaju surowca liczona na
  bieżąco: przy remisie każdy z remisujących dostaje pełne 10, a przy zerze
  nikt. Premia od razu podnosi wynik na liście, bez osobnych opisów,
  a prowadzący w danym surowcu jest wyróżniony na swojej karcie.
- Sekcja surowców w punktacji miasta jest zwijana.
- Świnka na polu: miasta po 4 pkt zamiast 3.

### Księżniczka i smok
- **Wróżka**: kafelek dopisuje graczowi od razu **1 pkt** (wróżka stoi przy
  jego ludku na początku tury), z możliwością cofnięcia z paska u dołu.
- **+3 pkt** za budowlę punktowaną z ludkiem przy wróżce to opcja
  „Wróżka przy ludku" przy mieście, drodze, klasztorze i polu; dodaje się do
  zwykłej punktacji, także gdy ta wynosi 0. Dotyczy też końca gry.
- Dodatek można wyłączyć w ustawieniach, wtedy znika kafelek i opcja.

### Mosty, zamki i bazary
- **Mosty** punktują jak płytki z drogą: płytkę z mostem liczysz raz, więc
  w osobnym liczniku wpisz tylko te płytki, których nie ma jeszcze w „Płytkach".
- **Zamki** na polach są warte 4 pkt zamiast 3 (ze świnką 5).
- **Zamek** przy mieście, drodze lub klasztorze: właściciel zamku dostaje
  punkty ukończonej budowli. Nie ma osobnego kafelka – pole **Punkty jako
  zamek** (z liczbą zamków) jest w punktacji miasta, drogi i klasztoru, a w
  sekcji **Punkty wspólne / zamki** każdy inny gracz może dostać punkty „jako
  zamek" (np. A i B dzielą miasto, C ma przy nim zamek). Punktujący ma w sekcji
  opcję „ma zamek": dostaje swoje punkty *i* punkty za zamek, a „Punkty jako
  zamek" to punkty wyłącznie z zamku. Wróżka i dyrektor cyrku liczą się tylko
  punktującemu, zamek na końcu gry nie punktuje.
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

## Wydania

Każdy merge do `master` uruchamia workflow **Release APK**: testy, budowa APK
i wydanie na GitHubie z kolejnym numerem wersji **v1, v2, v3…** Numer jest
liczony z istniejących tagów `vN` (starsze, jak `v1.0.4`, są pomijane) i trafia
też do aplikacji jako wersja i kod wersji Androida. Workflow można odpalić
ręcznie z zakładki Actions.
