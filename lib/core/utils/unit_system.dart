/// Distance/pace unit preference. Persisted as the string 'km' | 'mi' in the
/// Settings table; the app stores all run data in SI (metres, seconds-per-km)
/// and converts only at display time via the helpers in `pace_format.dart`.
enum UnitSystem {
  km,
  mi;

  /// Maps the persisted string ('km'|'mi') to a [UnitSystem], defaulting to
  /// [UnitSystem.km] for any unknown/legacy value.
  static UnitSystem fromString(String? value) =>
      value == 'mi' ? UnitSystem.mi : UnitSystem.km;

  /// The value stored in the Settings table.
  String get storageValue => this == UnitSystem.mi ? 'mi' : 'km';
}

/// Metres in one statute mile.
const double metersPerMile = 1609.344;
