import SwiftUI

struct FlashcardView: View {
    @ObservedObject var viewModel: DeckViewModel

    var body: some View {
        if let card = viewModel.currentCard {
            cardContent(card)
                .id("\(card.id)-\(viewModel.currentIndex)")
        } else {
            emptyState
        }
    }

    private func cardContent(_ card: VocabularyItem) -> some View {
        VStack(spacing: 0) {
            // Card
            ZStack {
                // Front face
                frontFace(card)
                    .opacity(viewModel.isFlipped ? 0 : 1)
                    .rotation3DEffect(
                        .degrees(viewModel.isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )

                // Back face
                backFace(card)
                    .opacity(viewModel.isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(viewModel.isFlipped ? 0 : -180),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }
            .frame(height: 290)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.5)) {
                    viewModel.flipCard()
                }
            }

            // Hint text
            if viewModel.hintLevel > 0 && !viewModel.isFlipped {
                HStack(spacing: 4) {
                    Text("Hint:")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.mid)
                    Text(viewModel.hintText)
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.red)
                        .tracking(2)
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
    }

    private func frontFace(_ card: VocabularyItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.light, lineWidth: 1.5)
                )

            VStack(spacing: 0) {
                // Category label top-left
                HStack {
                    Text(card.category.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.7)
                        .foregroundColor(AppColors.mid.opacity(0.4))
                    Spacer()

                    // Pile badge
                    if let sr = viewModel.srCards[String(card.id)] {
                        pileBadge(sr.pile)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                Text(viewModel.promptLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(AppColors.mid.opacity(0.45))
                    .padding(.bottom, 12)

                Text(viewModel.promptWord)
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColors.dark)
                    .padding(.horizontal, 24)

                Spacer()

                Text("Tap to flip")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mid.opacity(0.3))
                    .tracking(0.7)
                    .padding(.bottom, 20)
            }
        }
    }

    private func backFace(_ card: VocabularyItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(card.categoryKey.color)
                .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

            VStack(spacing: 12) {
                Text(viewModel.answerLabel)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.5))

                Text(viewModel.answerWord)
                    .font(.custom("Georgia", size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)

                Text(card.category.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.8)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
            }
        }
    }

    private func pileBadge(_ pile: Int) -> some View {
        let (text, color): (String, Color) = {
            switch pile {
            case 0: return ("H", Color.red)
            case 1: return ("O", AppColors.gold)
            case 2: return ("G", AppColors.hgreen)
            default: return ("", .clear)
            }
        }()

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .frame(width: 20, height: 20)
            .background(color.opacity(0.15))
            .clipShape(Circle())
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
