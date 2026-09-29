/// Whether trigonometric functions (`sin`, `cos`, `tan`, `asin`, `acos`,
/// `atan`) work in degrees or radians. Never affects the hyperbolic
/// functions (`sinh`, `cosh`, `tanh`), which have no angle unit.
enum AngleMode {
  /// `sin(90)` = 1.
  degrees,

  /// `sin(π/2)` = 1.
  radians,
}
