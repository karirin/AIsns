//
//  HelpModalView.swift
//  AIsns
//
//  Created by Apple on 2026/01/02.
//

import SwiftUI

struct HelpModalView: View {
    private let dbManager = FirebaseDatabaseManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @State var toggle = false
    @State private var text: String = ""
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @FocusState private var isFocused: Bool
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented        // Binding を保持
        UITextView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        ZStack {
            // 背景オーバーレイ - より滑らかなトランジション用にアニメーション追加
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            // メインモーダルコンテンツ
            VStack(spacing: 10) {
                // ヘッダー部分
                VStack(alignment: .center, spacing: 15) {
                    Text("お問い合わせ")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                    Text("ご意見やご要望がありましたら、お気軽にお知らせください。可能な限り対応いたします。")
                        .font(.system(size: isSmallDevice() ? 16 : 17))
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 5)
                        .foregroundColor(.black)
                }
                
                // テキスト入力エリア - より洗練されたデザイン
                VStack(alignment: .leading, spacing: 8) {
                    Text("問い合わせ内容")
                        .font(.subheadline)
                        .foregroundStyle(.black)
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty && !isFocused {
                            Text("例）投稿することができない")
                                .foregroundColor(Color(.gray))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                        }
                        TextEditor(text: $text)
                            .focused($isFocused)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(colorScheme == .dark ? .black : .black)
                    }
                    .background(colorScheme == .dark ? Color(.white) : Color.white)
                    .frame(height: 120)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                }
                .padding(.vertical, 5)
                
                // 送信ボタン - より現代的なデザイン
                Button(action: {
                    if toggle {
                        dbManager.updateUserFlag(userId: dbManager.currentUserId, userFlag: 1) { _ in }
                    }
                    dbManager.updateContact(userId: dbManager.currentUserId, newContact: text){ success in
                        if success {
                            alertTitle = "送信完了"
                            alertMessage = "お問い合わせいただきありがとうございます🙇"
                            showAlert = true
//                            isPresented = false
                        }
                    }
                }) {
                    Text("送信")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(text.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .cornerRadius(15)
                        .shadow(color: text.isEmpty ? .clear : Color.blue.opacity(0.3), radius: 5, y: 2)
                }
                .disabled(text.isEmpty)
                .padding(.vertical, 10)
                
                // トグルスイッチ - より整理されたデザイン
                HStack {
                    Toggle("今後は表示しない", isOn: $toggle)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .font(.subheadline)
                        .foregroundStyle(.black)
                    Spacer()
                }
                .padding(.vertical, 5)
            }
            .padding(25)
            .background(
                // モーダル背景 - より美しいグラデーション
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
            )
            .frame(width: isSmallDevice() ? 320 : 350)
            .overlay(
                // 閉じるボタン - よりエレガントなデザイン
                Button(action: {
                    if toggle {
                        dbManager.updateUserFlag(userId: dbManager.currentUserId, userFlag: 1) { _ in }
                    }
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .padding(16),
                alignment: .topTrailing
            )
        }
        .alert(isPresented: $showAlert) { // アラートを表示する
            Alert(
                title: Text("送信されました"),
                message: Text("お問い合わせいただきありがとうございます。"),
                dismissButton: .default(Text("OK")) {
                    isPresented = false
                }
            )
        }
    }
    
    func isSmallDevice() -> Bool {
        return UIScreen.main.bounds.width < 390
    }
}

#Preview{
    HelpModalView(isPresented: .constant(false))
}
