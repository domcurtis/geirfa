import SwiftUI

struct ProgressBarView: View {
    @ObservedObject var viewModel: DeckViewModel

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(viewModel.progressText)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mid)
                Spacer()
                Text("\(Int(viewModel.progressFraction * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mid)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.light)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(viewModel.isReviewMode ? AppColors.gold : AppColors.hgreen)
                        .frame(width: max(0, geo.size.width * viewModel.progressFraction), height: 4)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.progressFraction)
                }
            }
            .frame(height: 4)
        }
    }
}
