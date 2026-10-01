/// The earliest date the calendar picker offers. The calculator itself
/// handles years 1 to 9999, but a picker over 10,000 years is not usable.
final DateTime pickerFirstDate = DateTime.utc(1900);

/// The latest date the calendar picker offers.
final DateTime pickerLastDate = DateTime.utc(2200, 12, 31);
