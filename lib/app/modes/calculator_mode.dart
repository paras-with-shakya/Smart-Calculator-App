/// The calculator modes, in the order the mode sheet and the navigation rail
/// list them.
///
/// This enum is the mode registry. Adding a value makes the compiler point at
/// every exhaustive switch that must handle it, such as the mode's name and
/// icon.
enum CalculatorMode { basic, scientific, programmer, finance, converter, date }
