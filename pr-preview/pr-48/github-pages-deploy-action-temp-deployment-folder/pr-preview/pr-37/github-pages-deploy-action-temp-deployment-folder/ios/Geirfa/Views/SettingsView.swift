import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: DeckViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Direction") {
                    Picker("Direction", selection: $viewModel.direction) {
                        Text("English \u{2192} Cymraeg").tag(Direction.englishToWelsh)
                        Text("Cymraeg \u{2192} English").tag(Direction.welshToEnglish)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.direction) { newDir in
                        viewModel.setDirection(newDir)
                    }
                }

                Section("Learning Mode") {
                    Picker("Mode", selection: $viewModel.mode) {
                        Label("Flip Cards", systemImage: "rectangle.on.rectangle.angled")
                            .tag(LearningMode.flip)
                        Label("Typing", systemImage: "keyboard")
                            .tag(LearningMode.typing)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.mode) { newMode in
                        viewModel.setMode(newMode)
                    }
                }

                Section("Unit Statistics") {
                    let stats = viewModel.pileStats
                    HStack(spacing: 16) {
                        StatBadge(label: "Hard", count: stats.hard, color: .red) {
                            if stats.hard > 0 { viewModel.reviewPile(0); dismiss() }
                        }
                        StatBadge(label: "Okay", count: stats.okay, color: AppColors.gold) {
                            if stats.okay > 0 { viewModel.reviewPile(1); dismiss() }
                        }
                        StatBadge(label: "Known", count: stats.known, color: AppColors.hgreen) {
                            if stats.known > 0 { viewModel.reviewPile(2); dismiss() }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(AppColors.mid)
            }
            .frame(minWidth: 70)
            .padding(.vertical, 8)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(count == 0 ? 0.4 : 1)
    }
}
