//
//  SettingsView.swift
//  AIsns
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: OshiViewModel
    @Binding var userName: String
    @Binding var userBio: String
    @Binding var avatarImage: UIImage?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false

    @State private var showingDeleteAlert = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?

    var body: some View {
        Form {
            Section("プロフィール") {
                NavigationLink {
                    UserProfileEditView(
                        userName: $userName,
                        userBio: $userBio,
                        avatarImage: $avatarImage
                    )
                } label: {
                    SettingsRow(
                        icon: "person.crop.circle",
                        iconColor: AppColors.primary,
                        title: "プロフィールを編集",
                        subtitle: userName
                    )
                }
            }

            Section("アプリ") {
                NavigationLink {
                    PlusPaywallView()
                } label: {
                    SettingsRow(
                        icon: "sparkles",
                        iconColor: AppColors.primary,
                        title: "AImate Plus",
                        subtitle: subscriptionStore.isPlusActive ? "利用中" : "広告なし・DM無制限"
                    )
                }

                if subscriptionStore.isPlusActive {
                    NavigationLink {
                        OshiConversationView(viewModel: viewModel)
                    } label: {
                        SettingsRow(
                            icon: "person.2.wave.2",
                            iconColor: Color(hex: "8B5CF6"),
                            title: "AI同士の会話",
                            subtitle: "テーマを決めて会話を生成"
                        )
                    }
                } else {
                    Button {
                        generateHapticFeedback()
                        viewModel.requestPlusPaywall(.premiumFeature, force: true)
                    } label: {
                        SettingsRow(
                            icon: "person.2.wave.2",
                            iconColor: Color(hex: "8B5CF6"),
                            title: "AI同士の会話",
                            subtitle: "Plus限定"
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    FollowListView(title: "フォロー中", type: .following, viewModel: viewModel)
                } label: {
                    SettingsRow(
                        icon: "person.2",
                        iconColor: AppColors.success,
                        title: "フォロー中",
                        subtitle: "\(viewModel.followingCount)人"
                    )
                }

                Button {
                    Task { await clearNotifications() }
                } label: {
                    SettingsRow(
                        icon: "bell.slash",
                        iconColor: AppColors.warning,
                        title: "通知をすべて既読",
                        subtitle: "\(viewModel.unreadNotificationCount)件の未読"
                    )
                }
                .buttonStyle(.plain)
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(AppColors.error, in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("退会する")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.error)
                            Text("この端末のアカウントデータを削除します")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .disabled(isDeletingAccount)
            } header: {
                Text("アカウント")
            } footer: {
                if let deleteErrorMessage {
                    Text(deleteErrorMessage)
                        .foregroundColor(AppColors.error)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(AuroraBackground())
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    AppColors.overlay
                        .ignoresSafeArea()
                    ProgressView("削除中...")
                        .padding(20)
                        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .alert("退会しますか?", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("退会する", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("プロフィール、投稿、フォロー、通知、チャット履歴を削除します。この操作は元に戻せません。")
        }
    }

    private func clearNotifications() async {
        do {
            try await FirebaseDatabaseManager.shared.clearAllNotifications()
            await MainActor.run {
                viewModel.notifications.removeAll()
            }
        } catch {
            await MainActor.run {
                deleteErrorMessage = "通知の更新に失敗しました。時間をおいて再試行してください。"
            }
        }
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        deleteErrorMessage = nil

        do {
            try await FirebaseDatabaseManager.shared.deleteCurrentUserData()
            await MainActor.run {
                viewModel.resetForAccountDeletion()
                userName = "あなた"
                userBio = ""
                avatarImage = nil
                hasSeenTutorial = false
                isDeletingAccount = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                deleteErrorMessage = "退会処理に失敗しました。通信状況を確認して再試行してください。"
                isDeletingAccount = false
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle.isEmpty ? "未設定" : subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            viewModel: OshiViewModel(mock: true),
            userName: .constant("あなた"),
            userBio: .constant(""),
            avatarImage: .constant(nil)
        )
        .environmentObject(SubscriptionStore())
    }
}
