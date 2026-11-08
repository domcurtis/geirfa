import SwiftUI

struct TypingView: View {
    @ObservedObject var viewModel: DeckViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        if let card = viewModel.currentCard {
            typingCard(card)
                .id("\(card.id)-\(viewModel.currentIndex)")
        } else {
            emptyState
        }
    }

    private func typingCard(_ card: VocabularyItem) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(borderColor, lineWidth: 1.5)
                    )

                VStack(spacing: 16) {
                    // Category label
                    Text(card.category.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.7)
                        .foregroundColor(AppColors.mid.opacity(0.4))

                    // Prompt label
                    Text(viewModel.promptLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(AppColors.mid.opacity(0.45))

                    // Prompt word
                    Text(viewModel.promptWord)
                        .font(.custom("Georgia", size: 24))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.dark)

                    // Divider
                    Divider()
                        .padding(.horizontal, 40)

                    // Answer label
                    Text(viewModel.answerLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(AppColors.mid.opacity(0.45))

                    // Text input
                    TextField("Type your answer...", text: $viewModel.typingAnswer)
                        .font(.system(size: 20, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isInputFocused)
                        .disabled(viewModel.typingResult != nil)
                        .onSubmit {
                            if viewModel.typingResult == nil {
                                viewModel.checkTypingAnswer()
                            }
                        }

                    // Result feedback
                    if let result = viewModel.typingResult {
                        resultView(result)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .padding(24)
            }
            .frame(minHeight: 290)

            // Hint text
            if viewModel.hintLevel > 0 && viewModel.typingResult == nil {
                HStack(spacing: 4) {
                    Text("Hint:")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mid)
                    Text(viewModel.hintText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(2)
                }
                .padding(.top, 8)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }

    private var borderColor: Color {
        switch viewModel.typingResult {
        case .correct:
            return AppColors.hgreen
        case .incorrect:
            return .red
        case nil:
            return AppColors.light
        }
    }

    @ViewBuilder
    private func resultView(_ result: DeckViewModel.TypingResult) -> some View {
        switch result {
        case .correct:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                Text("Correct!")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppColors.hgreen)

        case .incorrect(let correct):
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Incorrect")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.red)

                Text(correct)
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.dark)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.hgreen)
            Text("No cards to review")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mid)
        }
        .frame(height: 290)
    }
}
