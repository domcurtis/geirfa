import SwiftUI

struct UnitBarView: View {
    @ObservedObject var viewModel: DeckViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(viewModel.units, id: \.self) { unit in
                        UnitButton(
                            unit: unit,
                            isActive: unit == viewModel.currentUnit && !viewModel.isReviewMode,
                            mastery: viewModel.unitMasteryState(unit)
                        ) {
                            viewModel.selectUnit(unit)
                        }
                        .id(unit)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(viewModel.currentUnit, anchor: .center)
                    }
                }
            }
            .onChange(of: viewModel.currentUnit) { newUnit in
                withAnimation {
                    proxy.scrollTo(newUnit, anchor: .center)
                }
            }
        }
    }
}

struct UnitButton: View {
    let unit: String
    let isActive: Bool
    let mastery: UnitMastery
    let action: () -> Void

    var displayName: String {
        if unit == "arholiad" { return "ARHOLIAD" }
        return unit
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if mastery == .mastered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                }
                Text(displayName)
            }
            .font(.system(size: 13, weight: .semibold))
            .tracking(0.5)
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(isActive ? AppColors.dark : .white)
            .foregroundColor(isActive ? .white : AppColors.mid)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? AppColors.dark :
                        mastery == .mastered ? AppColors.hgreen :
                        mastery == .partial ? AppColors.gold :
                        AppColors.light,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
