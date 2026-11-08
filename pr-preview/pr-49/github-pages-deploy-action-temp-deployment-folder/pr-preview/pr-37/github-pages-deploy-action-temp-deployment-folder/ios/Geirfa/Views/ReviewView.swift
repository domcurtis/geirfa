import SwiftUI

struct ReviewBanner: View {
    @ObservedObject var viewModel: DeckViewModel

    var body: some View {
        if viewModel.isReviewMode {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundColor(AppColors.gold)
                Text("Review Mode")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.gold)
                Text("(\(viewModel.deck.count) cards)")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.mid)
                Spacer()
                Button {
                    viewModel.exitReview()
                } label: {
                    Text("Exit")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.reviewBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct ReviewFAB: View {
    @ObservedObject var viewModel: DeckViewModel

    var body: some View {
        if viewModel.canShowReviewButton && !viewModel.isReviewMode {
            Button {
                viewModel.startReview()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Review \(viewModel.overdueCount)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(AppColors.gold)
                .clipShape(Capsule())
                .shadow(color: AppColors.gold.opacity(0.3), radius: 8, y: 4)
            }
        }
    }
}
