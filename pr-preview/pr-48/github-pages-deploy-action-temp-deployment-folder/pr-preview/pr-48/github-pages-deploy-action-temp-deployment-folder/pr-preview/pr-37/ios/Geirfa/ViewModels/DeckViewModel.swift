import Foundation
import SwiftUI

@MainActor
final class DeckViewModel: ObservableObject {
    // MARK: - Published State

    @Published var allVocab: [VocabularyItem] = []
    @Published var currentUnit: String = "1"
    @Published var direction: Direction = .englishToWelsh
    @Published var mode: LearningMode = .flip
    @Published var deck: [Int] = []           // indices into allVocab
    @Published var currentIndex: Int = 0
    @Published var isFlipped: Bool = false
    @Published var srCards: [String: SRCard] = [:]
    @Published var masteredUnits: Set<String> = []
    @Published var isReviewMode: Bool = false
    @Published var hintLevel: Int = 0
    @Published var showMastery: Bool = false
    @Published var showSettings: Bool = false
    @Published var typingAnswer: String = ""
    @Published var typingResult: TypingResult? = nil

    enum TypingResult {
        case correct
        case incorrect(correct: String)
    }

    private let storage = StorageService.shared

    // MARK: - Computed Properties

    var units: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for item in allVocab {
            if seen.insert(item.unit).inserted {
                ordered.append(item.unit)
            }
        }
        return ordered
    }

    var unitVocab: [VocabularyItem] {
        allVocab.filter { $0.unit == currentUnit }
    }

    var currentCard: VocabularyItem? {
        guard currentIndex >= 0, currentIndex < deck.count else { return nil }
        let vocabIndex = deck[currentIndex]
        guard vocabIndex < allVocab.count else { return nil }
        return allVocab[vocabIndex]
    }

    var promptWord: String {
        guard let card = currentCard else { return "" }
        return direction == .englishToWelsh ? card.wordEnglish : card.wordWelsh
    }

    var answerWord: String {
        guard let card = currentCard else { return "" }
        return direction == .englishToWelsh ? card.wordWelsh : card.wordEnglish
    }

    var promptLabel: String {
        direction == .englishToWelsh ? "ENGLISH" : "CYMRAEG"
    }

    var answerLabel: String {
        direction == .englishToWelsh ? "CYMRAEG" : "ENGLISH"
    }

    var progressFraction: Double {
        guard !deck.isEmpty else { return 0 }
        return Double(currentIndex) / Double(deck.count)
    }

    var progressText: String {
        guard !deck.isEmpty else { return "0 / 0" }
        return "\(currentIndex + 1) / \(deck.count)"
    }

    var pileStats: (hard: Int, okay: Int, known: Int) {
        let vocabIndices = unitVocab.map { $0.id }
        var hard = 0, okay = 0, known = 0
        for idx in vocabIndices {
            let card = srCards[String(idx)]
            switch card?.pile {
            case 0: hard += 1
            case 1: okay += 1
            case 2: known += 1
            default: hard += 1 // unseen cards count as hard
            }
        }
        return (hard, okay, known)
    }

    var overdueCount: Int {
        srCards.values.filter { $0.pile == 2 && $0.isOverdue }.count
    }

    var canShowReviewButton: Bool {
        overdueCount > 0
    }

    // MARK: - Hints (Welsh digraph-aware)

    private static let welshDigraphs = ["ch", "dd", "ff", "ng", "ll", "ph", "rh", "th"]

    func welshLetters(_ word: String) -> [String] {
        var letters: [String] = []
        let lower = word.lowercased()
        var i = lower.startIndex
        while i < lower.endIndex {
            var matched = false
            for digraph in Self.welshDigraphs {
                if lower[i...].hasPrefix(digraph) {
                    letters.append(String(word[i..<word.index(i, offsetBy: digraph.count)]))
                    i = word.index(i, offsetBy: digraph.count)
                    matched = true
                    break
                }
            }
            if !matched {
                letters.append(String(word[i]))
                i = word.index(after: i)
            }
        }
        return letters
    }

    var hintText: String {
        guard hintLevel > 0 else { return "" }
        let targetWord = direction == .englishToWelsh ? (currentCard?.wordWelsh ?? "") : (currentCard?.wordEnglish ?? "")
        let letters = welshLetters(targetWord)
        let revealed = min(hintLevel, letters.count)
        return letters.prefix(revealed).joined()
    }

    var canHint: Bool {
        guard let card = currentCard else { return false }
        let targetWord = direction == .englishToWelsh ? card.wordWelsh : card.wordEnglish
        return hintLevel < welshLetters(targetWord).count
    }

    // MARK: - Initialization

    func load() {
        loadVocabulary()
        srCards = storage.loadSRCards()
        currentUnit = storage.currentUnit
        direction = storage.direction
        mode = storage.mode
        masteredUnits = storage.loadMasteredUnits()
        rebuildDeck()
    }

    private func loadVocabulary() {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        guard let items = try? decoder.decode([VocabularyItem].self, from: data) else { return }
        allVocab = items.enumerated().map { $0.element.withIndex($0.offset) }
    }

    // MARK: - Deck Management

    func rebuildDeck() {
        let vocabForUnit = allVocab.filter { $0.unit == currentUnit }

        var hardPile: [Int] = []
        var okayPile: [Int] = []
        var knownPile: [Int] = []

        for item in vocabForUnit {
            let key = String(item.id)
            guard let card = srCards[key] else {
                hardPile.append(item.id)
                continue
            }
            switch card.pile {
            case 0: hardPile.append(item.id)
            case 1: okayPile.append(item.id)
            case 2: knownPile.append(item.id)
            default: hardPile.append(item.id)
            }
        }

        hardPile.shuffle()
        okayPile.shuffle()
        knownPile.shuffle()

        deck = hardPile + okayPile + knownPile
        currentIndex = 0
        isFlipped = false
        hintLevel = 0
        typingAnswer = ""
        typingResult = nil
    }

    // MARK: - Unit Selection

    func selectUnit(_ unit: String) {
        guard unit != currentUnit || isReviewMode else { return }
        isReviewMode = false
        currentUnit = unit
        storage.currentUnit = unit
        rebuildDeck()
    }

    // MARK: - Direction & Mode

    func toggleDirection() {
        setDirection(direction == .englishToWelsh ? .welshToEnglish : .englishToWelsh)
    }

    func setDirection(_ dir: Direction) {
        direction = dir
        storage.direction = dir
        isFlipped = false
        hintLevel = 0
    }

    func setMode(_ newMode: LearningMode) {
        mode = newMode
        storage.mode = newMode
        isFlipped = false
        typingAnswer = ""
        typingResult = nil
        hintLevel = 0
    }

    // MARK: - Card Interaction

    func flipCard() {
        guard !deck.isEmpty else { return }
        isFlipped.toggle()
    }

    func revealHint() {
        hintLevel += 1
    }

    // MARK: - Rating

    func rateCard(_ rating: Int) {
        guard let card = currentCard else { return }
        let key = String(card.id)
        var sr = srCards[key] ?? SRCard.new()

        sr.totalReviews += 1

        switch rating {
        case 0: // Hard
            sr.pile = 0
            sr.box = max(0, sr.box - 5)
            sr.streak = 0
            sr.reviewAfter = Date()
        case 1: // Okay
            sr.pile = 1
            sr.box = max(0, sr.box - 3)
            sr.streak = 0
            sr.reviewAfter = Date()
        case 2: // Got it
            sr.pile = 2
            sr.box = min(SRCard.boxIntervals.count - 1, sr.box + 1)
            sr.streak += 1
            sr.totalCorrect += 1
            let interval = SRCard.boxIntervals[sr.box]
            sr.reviewAfter = Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
        default:
            break
        }

        srCards[key] = sr
        storage.saveSRCards(srCards)

        // Check mastery
        if !isReviewMode {
            checkMastery()
        }

        advanceCard()
    }

    private func advanceCard() {
        isFlipped = false
        hintLevel = 0
        typingAnswer = ""
        typingResult = nil

        if isReviewMode {
            // In review mode, remove current card and stay at same index
            if currentIndex < deck.count {
                deck.remove(at: currentIndex)
            }
            if deck.isEmpty {
                exitReview()
                return
            }
            if currentIndex >= deck.count {
                currentIndex = 0
            }
        } else {
            if currentIndex + 1 < deck.count {
                currentIndex += 1
            } else {
                // End of deck — rebuild to reorder by piles
                rebuildDeck()
            }
        }
    }

    private func checkMastery() {
        let vocabForUnit = allVocab.filter { $0.unit == currentUnit }
        let allKnown = vocabForUnit.allSatisfy { item in
            srCards[String(item.id)]?.pile == 2
        }
        if allKnown && !masteredUnits.contains(currentUnit) {
            masteredUnits.insert(currentUnit)
            storage.saveMasteredUnits(masteredUnits)
            showMastery = true
        }
    }

    func dismissMastery() {
        showMastery = false
    }

    // MARK: - Review Mode

    func startReview() {
        let overdue = srCards.filter { $0.value.pile == 2 && $0.value.isOverdue }
        let sorted = overdue.sorted { $0.value.urgencyRatio > $1.value.urgencyRatio }
        let top = Array(sorted.prefix(20).shuffled().prefix(10))

        guard !top.isEmpty else { return }

        isReviewMode = true
        deck = top.compactMap { Int($0.key) }
        currentIndex = 0
        isFlipped = false
        hintLevel = 0
    }

    func exitReview() {
        isReviewMode = false
        rebuildDeck()
    }

    // MARK: - Review by Pile

    func reviewPile(_ pile: Int) {
        let vocabForUnit = allVocab.filter { $0.unit == currentUnit }
        var pileCards: [Int] = []

        for item in vocabForUnit {
            let key = String(item.id)
            let card = srCards[key]
            let currentPile = card?.pile ?? 0
            if currentPile == pile || (pile == 0 && card == nil) {
                pileCards.append(item.id)
            }
        }

        guard !pileCards.isEmpty else { return }

        isReviewMode = true
        deck = pileCards.shuffled()
        currentIndex = 0
        isFlipped = false
        hintLevel = 0
    }

    // MARK: - Typing Mode

    func checkTypingAnswer() {
        let correct = answerWord
        let normalizedAnswer = typingAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrect = correct.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedAnswer == normalizedCorrect {
            typingResult = .correct
        } else {
            typingResult = .incorrect(correct: correct)
        }
    }

    func unitMasteryState(_ unit: String) -> UnitMastery {
        if masteredUnits.contains(unit) { return .mastered }
        let vocabForUnit = allVocab.filter { $0.unit == unit }
        let hasProgress = vocabForUnit.contains { srCards[String($0.id)] != nil }
        return hasProgress ? .partial : .none
    }
}

enum UnitMastery {
    case none
    case partial
    case mastered
}
