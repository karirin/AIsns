import SwiftUI

struct OshiConversationView: View {
    @ObservedObject var viewModel: OshiViewModel
    @EnvironmentObject private var subscriptionStore: SubscriptionStore

    @State private var firstOshiId: UUID?
    @State private var secondOshiId: UUID?
    @State private var theme = ""
    @State private var conversation = ""
    @State private var isGenerating = false

    private var selectableOshis: [OshiCharacter] {
        viewModel.oshiList.filter { $0.isFollowedByUser || $0.isFollowingUser || $0.isCreatedByUser }
    }

    private var firstOshi: OshiCharacter? {
        selectableOshis.first { $0.id == firstOshiId }
    }

    private var secondOshi: OshiCharacter? {
        selectableOshis.first { $0.id == secondOshiId }
    }

    private var canGenerate: Bool {
        subscriptionStore.isPlusActive &&
        firstOshi != nil &&
        secondOshi != nil &&
        firstOshiId != secondOshiId &&
        !theme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isGenerating
    }

    var body: some View {
        Form {
            if !subscriptionStore.isPlusActive {
                Section {
                    Button {
                        generateHapticFeedback()
                        viewModel.requestPlusPaywall(.premiumFeature, force: true)
                    } label: {
                        Label("PlusでAI同士の会話を使う", systemImage: "sparkles")
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("会話するAI") {
                Picker("1人目", selection: $firstOshiId) {
                    Text("選択").tag(Optional<UUID>.none)
                    ForEach(selectableOshis) { oshi in
                        Text(oshi.name).tag(Optional(oshi.id))
                    }
                }

                Picker("2人目", selection: $secondOshiId) {
                    Text("選択").tag(Optional<UUID>.none)
                    ForEach(selectableOshis) { oshi in
                        Text(oshi.name).tag(Optional(oshi.id))
                    }
                }
            }

            Section("テーマ") {
                TextField("例: 最近のユーザーの投稿について", text: $theme, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Button {
                    if subscriptionStore.isPlusActive {
                        Task { await generateConversation() }
                    } else {
                        generateHapticFeedback()
                        viewModel.requestPlusPaywall(.premiumFeature, force: true)
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("会話を生成")
                                .font(AppTypography.bodyMedium)
                        }
                        Spacer()
                    }
                }
                .disabled(subscriptionStore.isPlusActive && !canGenerate)
            }

            if !conversation.isEmpty {
                Section("会話") {
                    Text(conversation)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                        .textSelection(.enabled)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AuroraBackground())
        .navigationTitle("AI同士の会話")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if firstOshiId == nil {
                firstOshiId = selectableOshis.first?.id
            }
            if secondOshiId == nil {
                secondOshiId = selectableOshis.dropFirst().first?.id
            }
        }
    }

    private func generateConversation() async {
        guard let firstOshi, let secondOshi else { return }
        isGenerating = true
        conversation = ""

        let result = await viewModel.generateOshiConversation(
            first: firstOshi,
            second: secondOshi,
            theme: theme
        )

        await MainActor.run {
            conversation = result
            isGenerating = false
        }
    }
}

#Preview {
    NavigationStack {
        OshiConversationView(viewModel: OshiViewModel(mock: true))
            .environmentObject(SubscriptionStore())
    }
}
