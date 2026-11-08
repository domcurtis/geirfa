import Foundation

struct VocabularyItem: Codable, Identifiable {
    let id: Int
    let wordEnglish: String
    let wordWelsh: String
    let category: String
    let level: String
    let unit: String

    enum CodingKeys: String, CodingKey {
        case wordEnglish = "word_english"
        case wordWelsh = "word_welsh"
        case category, level, unit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wordEnglish = try container.decode(String.self, forKey: .wordEnglish)
        self.wordWelsh = try container.decode(String.self, forKey: .wordWelsh)
        self.category = try container.decode(String.self, forKey: .category)
        self.level = try container.decode(String.self, forKey: .level)
        self.unit = try container.decode(String.self, forKey: .unit)
        // id is set after decoding via setIndex
        self.id = 0
    }

    init(id: Int, wordEnglish: String, wordWelsh: String, category: String, level: String, unit: String) {
        self.id = id
        self.wordEnglish = wordEnglish
        self.wordWelsh = wordWelsh
        self.category = category
        self.level = level
        self.unit = unit
    }

    func withIndex(_ index: Int) -> VocabularyItem {
        VocabularyItem(id: index, wordEnglish: wordEnglish, wordWelsh: wordWelsh,
                       category: category, level: level, unit: unit)
    }

    var categoryKey: CategoryType {
        switch category.lowercased() {
        case let c where c.contains("feminine"):
            return .feminine
        case let c where c.contains("masculine"):
            return .masculine
        case "verb":
            return .verb
        case "adjective":
            return .adjective
        default:
            return .other
        }
    }
}

enum CategoryType: String, CaseIterable {
    case feminine
    case masculine
    case verb
    case adjective
    case other
}

enum Direction: String, Codable {
    case englishToWelsh
    case welshToEnglish
}

enum LearningMode: String, Codable {
    case flip
    case typing
}
