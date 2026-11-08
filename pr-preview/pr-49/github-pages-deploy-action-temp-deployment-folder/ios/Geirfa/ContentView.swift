import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = DeckViewModel()

    var body: some View {
        ZStack {
            // Background
            (viewModel.isReviewMode ? AppColors.reviewBg : AppColors.cream)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.bottom, 12)

                // Unit bar
                UnitBarView(viewModel: viewModel)
                    .padding(.bottom, 8)

                // Review banner
                ReviewBanner(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                // Progress bar
                ProgressBarView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                Spacer()

                // Card area
                Group {
                    if viewModel.mode == .flip {
                        FlashcardView(viewModel: viewModel)
                    } else {
                        TypingView(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // Review FAB
                ReviewFAB(viewModel: viewModel)
                    .padding(.bottom, 8)
            }

            // Mastery celebration
            ConfettiView(isShowing: $viewModel.showMastery)
        }
        .onAppear {
            viewModel.load()
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Text("Geirfa")
                            .font(.custom("Georgia", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.dark)
                        Text(".")
                            .font(.custom("Georgia", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.hgreen)
                    }
                    Text("WELSH VOCABULARY")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(AppColors.mid)
                }
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button {
                    viewModel.showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.mid)
                        .frame(width: 36, height: 36)
                        .background(.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(AppColors.light, lineWidth: 1.5)
                        )
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .overlay(alignment: .bottom) {
            Divider()
                .background(AppColors.light)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if viewModel.mode == .flip {
                flipModeButtons
            } else {
                typingModeButtons
            }
        }
    }

    @ViewBuilder
    private var flipModeButtons: some View {
        if viewModel.isFlipped {
            // Rating buttons
            HStack(spacing: 8) {
                ratingButton("Hard", rating: 0, color: .red)
                ratingButton("Okay", rating: 1, color: AppColors.gold)
                ratingButton("Got it", rating: 2, color: AppColors.hgreen)
            }
        } else {
            // Pre-flip buttons
            HStack(spacing: 8) {
                // Hint button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.revealHint()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb")
                        Text("Hint")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mid)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.light, lineWidth: 1.5)
                    )
                }
                .disabled(!viewModel.canHint)
                .opacity(viewModel.canHint ? 1 : 0.35)

                // Shuffle button
                Button {
                    viewModel.rebuildDeck()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mid)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.light, lineWidth: 1.5)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var typingModeButtons: some View {
        if viewModel.typingResult != nil {
            // After answer submitted — show rating buttons
            HStack(spacing: 8) {
                ratingButton("Hard", rating: 0, color: .red)
                ratingButton("Okay", rating: 1, color: AppColors.gold)
                ratingButton("Got it", rating: 2, color: AppColors.hgreen)
            }
        } else {
            // Before answer — show check and hint buttons
            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.revealHint()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb")
                        Text("Hint")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mid)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.light, lineWidth: 1.5)
                    )
                }
                .disabled(!viewModel.canHint)
                .opacity(viewModel.canHint ? 1 : 0.35)

                Button {
                    viewModel.checkTypingAnswer()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Check")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(AppColors.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(viewModel.typingAnswer.isEmpty)
                .opacity(viewModel.typingAnswer.isEmpty ? 0.5 : 1)
            }
        }
    }

    private func ratingButton(_ label: String, rating: Int, color: Color) -> some View {
        Button {
            viewModel.rateCard(rating)
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
