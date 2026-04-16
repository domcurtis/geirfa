import Foundation

struct SRCard: Codable {
    var pile: Int       // 0 = hard, 1 = okay, 2 = got it
    var box: Int        // 0-8 Leitner box
    var streak: Int
    var reviewAfter: Date
    var totalReviews: Int
    var totalCorrect: Int

    static let boxIntervals = [0, 1, 3, 7, 14, 30, 90, 180, 365]

    static func new() -> SRCard {
        SRCard(pile: 0, box: 0, streak: 0, reviewAfter: .distantPast,
               totalReviews: 0, totalCorrect: 0)
    }

    var isOverdue: Bool {
        Date() >= reviewAfter
    }

    var urgencyRatio: Double {
        guard pile == 2, reviewAfter < Date() else { return 0 }
        let interval = SRCard.boxIntervals[min(box, SRCard.boxIntervals.count - 1)]
        guard interval > 0 else { return 0 }
        let overdueDays = Date().timeIntervalSince(reviewAfter) / 86400
        return overdueDays / Double(interval)
    }
}
