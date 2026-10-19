/// Rodzaje punktacji dostępne w aplikacji.
enum ScoringType {
  city('Miasto', 'assets/images/city.jpg'),
  road('Droga', 'assets/images/road.jpg'),
  cloister('Klasztor', 'assets/images/cloister.jpg'),
  meadow('Pola', 'assets/images/meadow.jpg'),
  fairy('Wróżka', 'assets/images/fairy.png'),
  sheep('Owce', 'assets/images/sheeps.jpg');

  const ScoringType(this.displayName, this.iconPath);

  final String displayName;
  final String iconPath;
}

/// Liczy punkty za dany obiekt.
///
/// - [tiles] – liczba płytek (dla pól: liczba ukończonych miast, dla wróżki
///   i owiec: wpisane punkty),
/// - [banners] – liczba sztandarów (tylko miasto),
/// - [completed] – czy miasto/droga/klasztor jest ukończony,
/// - [bonus] – katedra (miasto), karczma (droga) lub świnka (pola).
int calculatePoints(
  ScoringType type, {
  required int tiles,
  int banners = 0,
  bool completed = true,
  bool bonus = false,
}) {
  switch (type) {
    case ScoringType.city:
      final count = tiles + banners;
      if (completed) return count * (bonus ? 3 : 2);
      // Niedokończone miasto z katedrą nie daje punktów.
      return bonus ? 0 : count;

    case ScoringType.road:
      if (completed) return tiles * (bonus ? 2 : 1);
      // Niedokończona droga z karczmą nie daje punktów.
      return bonus ? 0 : tiles;

    case ScoringType.cloister:
      return completed ? 9 : tiles;

    case ScoringType.meadow:
      return tiles * (bonus ? 4 : 3);

    case ScoringType.fairy:
    case ScoringType.sheep:
      return tiles;
  }
}
