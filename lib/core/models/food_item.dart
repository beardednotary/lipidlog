/// A food item with lipid impact metadata for the Impact Simulator.
///
/// [impactScore] is the estimated score change per lab cycle (~90 days) of
/// regular consumption at a standard serving size.
///   Positive  → score improves (good foods)
///   Negative  → score worsens (limit/avoid foods)
class FoodItem {
  final String name;
  final FoodCategory category;

  /// Estimated overall score delta per 90-day lab cycle.
  final double impactScore;

  /// Short label shown on the card, e.g. "Supports LDL reduction"
  final String impactLabel;

  /// One-line mechanism, e.g. "High in soluble fiber"
  final String mechanismNote;

  /// Bullet-point benefits (good foods) or risks (limit/avoid foods)
  final List<String> details;

  /// True if this food primarily targets LDL
  final bool helpsLdl;

  /// True if this food primarily targets triglycerides
  final bool helpsTriglycerides;

  const FoodItem({
    required this.name,
    required this.category,
    required this.impactScore,
    required this.impactLabel,
    required this.mechanismNote,
    this.details = const [],
    this.helpsLdl = false,
    this.helpsTriglycerides = false,
  });
}

enum FoodCategory { good, limit, avoid }
