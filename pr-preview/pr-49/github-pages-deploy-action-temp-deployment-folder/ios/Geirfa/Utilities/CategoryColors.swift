import SwiftUI

extension CategoryType {
    var color: Color {
        switch self {
        case .feminine:  return Color(red: 0.722, green: 0.196, blue: 0.196) // #b83232
        case .masculine: return Color(red: 0.141, green: 0.443, blue: 0.639) // #2471a3
        case .verb:      return Color(red: 0.478, green: 0.478, blue: 0.478) // #7a7a7a
        case .adjective: return Color(red: 0.102, green: 0.420, blue: 0.235) // #1a6b3c
        case .other:     return Color(red: 0.490, green: 0.373, blue: 0.647) // #7d5fa5
        }
    }

    var displayName: String {
        switch self {
        case .feminine:  return "feminine noun"
        case .masculine: return "masculine noun"
        case .verb:      return "verb"
        case .adjective: return "adjective"
        case .other:     return "other"
        }
    }
}

enum AppColors {
    static let cream = Color(red: 0.980, green: 0.969, blue: 0.949)       // #faf7f2
    static let dark = Color(red: 0.110, green: 0.110, blue: 0.110)        // #1c1c1c
    static let mid = Color(red: 0.353, green: 0.353, blue: 0.353)         // #5a5a5a
    static let light = Color(red: 0.910, green: 0.886, blue: 0.851)      // #e8e2d9
    static let gold = Color(red: 0.784, green: 0.659, blue: 0.294)       // #c8a84b
    static let hgreen = Color(red: 0.102, green: 0.420, blue: 0.235)     // #1a6b3c
    static let reviewBg = Color(red: 0.949, green: 0.937, blue: 0.894)   // #f2efe4
}
