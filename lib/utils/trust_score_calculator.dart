class TrustScoreCalculator {
  /// Dynamically calculates a user's trust score percentage (0% - 100%).
  /// Base score is 95% for clean accounts.
  static int calculate({
    required int completedBorrows,
    required int successfulReturns,
    required double averageRating,
    int cancelledRequests = 0,
    int reportsCount = 0,
  }) {
    if (completedBorrows == 0 && successfulReturns == 0 && averageRating == 0.0) {
      return 95; // Default welcoming score for new community members
    }

    double score = 85.0;

    // Add bonus for completed activity
    final totalSuccess = completedBorrows + successfulReturns;
    score += (totalSuccess * 1.5).clamp(0, 10);

    // Rating contribution (5.0 rating gives +5%, lower rating subtracts)
    if (averageRating > 0) {
      score += (averageRating - 4.0) * 5.0;
    }

    // Penalties for cancellations or reports
    score -= (cancelledRequests * 2.0);
    score -= (reportsCount * 10.0);

    return score.clamp(50, 100).round();
  }
}
