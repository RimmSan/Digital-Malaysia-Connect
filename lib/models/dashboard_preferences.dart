// ============================================================
// DASHBOARD PREFERENCES MODEL
// ------------------------------------------------------------
// Backs the "Customize Dashboard" personalization feature - lets
// the user show/hide individual dashboard sections. Persisted
// locally, separate from DashboardNote (My Insights).
// ============================================================

class DashboardPreferences {
  bool showInternetCard;
  bool showDomainsCard;
  bool showPopulationCard;
  bool showTrends;
  bool showHighlights;

  DashboardPreferences({
    this.showInternetCard = true,
    this.showDomainsCard = true,
    this.showPopulationCard = true,
    this.showTrends = true,
    this.showHighlights = true,
  });

  DashboardPreferences copyWith({
    bool? showInternetCard,
    bool? showDomainsCard,
    bool? showPopulationCard,
    bool? showTrends,
    bool? showHighlights,
  }) {
    return DashboardPreferences(
      showInternetCard: showInternetCard ?? this.showInternetCard,
      showDomainsCard: showDomainsCard ?? this.showDomainsCard,
      showPopulationCard: showPopulationCard ?? this.showPopulationCard,
      showTrends: showTrends ?? this.showTrends,
      showHighlights: showHighlights ?? this.showHighlights,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showInternetCard': showInternetCard,
      'showDomainsCard': showDomainsCard,
      'showPopulationCard': showPopulationCard,
      'showTrends': showTrends,
      'showHighlights': showHighlights,
    };
  }

  factory DashboardPreferences.fromJson(Map<String, dynamic> json) {
    return DashboardPreferences(
      showInternetCard: json['showInternetCard'] as bool? ?? true,
      showDomainsCard: json['showDomainsCard'] as bool? ?? true,
      showPopulationCard: json['showPopulationCard'] as bool? ?? true,
      showTrends: json['showTrends'] as bool? ?? true,
      showHighlights: json['showHighlights'] as bool? ?? true,
    );
  }
}
