import Foundation

final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let srCards = "welsh_sr_cards"
        static let currentUnit = "welsh_current_unit"
        static let direction = "welsh_direction"
        static let mode = "welsh_mode"
        static let masteredUnits = "welsh_mastered_units"
    }

    private init() {}

    // MARK: - SR Cards

    func loadSRCards() -> [String: SRCard] {
        guard let data = defaults.data(forKey: Keys.srCards),
              let cards = try? decoder.decode([String: SRCard].self, from: data) else {
            return [:]
        }
        return cards
    }

    func saveSRCards(_ cards: [String: SRCard]) {
        if let data = try? encoder.encode(cards) {
            defaults.set(data, forKey: Keys.srCards)
        }
    }

    // MARK: - Unit

    var currentUnit: String {
        get { defaults.string(forKey: Keys.currentUnit) ?? "1" }
        set { defaults.set(newValue, forKey: Keys.currentUnit) }
    }

    // MARK: - Direction

    var direction: Direction {
        get {
            guard let raw = defaults.string(forKey: Keys.direction),
                  let dir = Direction(rawValue: raw) else { return .englishToWelsh }
            return dir
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.direction) }
    }

    // MARK: - Mode

    var mode: LearningMode {
        get {
            guard let raw = defaults.string(forKey: Keys.mode),
                  let m = LearningMode(rawValue: raw) else { return .flip }
            return m
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.mode) }
    }

    // MARK: - Mastered Units

    func loadMasteredUnits() -> Set<String> {
        guard let data = defaults.data(forKey: Keys.masteredUnits),
              let units = try? decoder.decode(Set<String>.self, from: data) else {
            return []
        }
        return units
    }

    func saveMasteredUnits(_ units: Set<String>) {
        if let data = try? encoder.encode(units) {
            defaults.set(data, forKey: Keys.masteredUnits)
        }
    }
}
