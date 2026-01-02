//
//  UserEditProfileView.swift
//  AIsns
//
//  Created by Apple on 2026/01/02.
//

import SwiftUI

struct UserProfileEditView: View {
    @Binding var userName: String
    @Binding var userBio: String
    @Binding var avatarImage: UIImage?
    
    @Environment(\.dismiss) var dismiss
    @State private var editingName: String = ""
    @State private var editingBio: String = ""
    @State private var showingImagePicker = false
    @State private var showingSaveConfirmation = false
    @State private var isLoadingImage = false
    @State private var isSaving = false
    @FocusState private var focusedField: Field?
    
    private let dbManager = FirebaseDatabaseManager.shared
    private let avatarSize: CGFloat = 110
    private let maxBioLength = 160
    
    enum Field {
        case name, bio
    }
    
    init(userName: Binding<String>, userBio: Binding<String>, avatarImage: Binding<UIImage?>) {
        self._userName = userName
        self._userBio = userBio
        self._avatarImage = avatarImage
        self._editingName = State(initialValue: userName.wrappedValue)
        self._editingBio = State(initialValue: userBio.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // アバター（ヘッダーに重ねて配置）
                    avatarEditSection
                    
                    // フォームセクション
                    formSection
                        .padding(.top, 8)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // 保存トースト
            if showingSaveConfirmation {
                saveToastOverlay
            }
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        .navigationTitle("プロフィールを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Text("キャンセル")
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("完了") {
                        focusedField = nil
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
        .onChange(of: editingBio) { newValue in
            if newValue.count > maxBioLength {
                editingBio = String(newValue.prefix(maxBioLength))
            }
        }
    }
    
    // MARK: - Avatar Edit Section
    
    private var avatarEditSection: some View {
        Button {
            generateHapticFeedback()
            showingImagePicker = true
        } label: {
            ZStack {
                // 白い背景リング
                Circle()
                    .fill(Color(.systemGroupedBackground))
                    .frame(width: avatarSize + 10, height: avatarSize + 10)
                
                // アバター
                avatarContent
                
                // 編集オーバーレイ
                editOverlay
            }
        }
        .buttonStyle(.plain)
    }
    
    private var avatarContent: some View {
        Group {
            if isLoadingImage {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            } else if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.7, blue: 1.0),
                                Color(red: 0.7, green: 0.5, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    private var editOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: avatarSize, height: avatarSize)
            
            VStack(spacing: 4) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 22, weight: .medium))
                
                Text("変更")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // 名前フィールド
            nameField
            
            // 自己紹介フィールド
            bioField
        }
        .padding(.horizontal, 16)
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("名前", systemImage: "person.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                TextField("名前を入力", text: $editingName)
                    .font(.body)
                    .focused($focusedField, equals: .name)
                
                if !editingName.isEmpty {
                    Button {
                        editingName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        focusedField == .name ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }
    
    private var bioField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("自己紹介", systemImage: "text.quote")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 文字数カウンター
                Text("\(editingBio.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(bioCountColor)
                +
                Text("/\(maxBioLength)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField("自己紹介を入力...", text: $editingBio, axis: .vertical)
                .font(.body)
                .lineLimit(4...8)
                .focused($focusedField, equals: .bio)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            focusedField == .bio ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
            
            // ヒントテキスト
            Text("あなたについて教えてください")
                .font(.caption)
                .foregroundColor(AppColors.textTertiary)
                .padding(.leading, 4)
        }
    }
    
    private var bioCountColor: Color {
        let remaining = maxBioLength - editingBio.count
        if remaining <= 0 {
            return .red
        } else if remaining <= 20 {
            return .orange
        }
        return .secondary
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            Task { await saveChanges() }
        } label: {
            Group {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("保存")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(canSave ? .accentColor : .secondary)
        }
        .disabled(!canSave || isSaving)
    }
    
    private var canSave: Bool {
        !editingName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Save Toast
    
    private var saveToastOverlay: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text("保存しました")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
            )
            .padding(.top, 60)
            
            Spacer()
        }
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    // MARK: - Save Action
    
    @MainActor
    private func saveChanges() async {
        focusedField = nil
        isSaving = true
        defer { isSaving = false }
        
        do {
            let uid = FirebaseConfig.shared.userId
            
            var newAvatarURL: String? = nil
            if let img = avatarImage {
                isLoadingImage = true
                newAvatarURL = try await FirebaseStorageManager.shared.uploadUserAvatar(img, userId: uid)
                isLoadingImage = false
            }
            
            try await dbManager.saveUserProfile(
                userName: editingName,
                userBio: editingBio,
                avatarImageURL: newAvatarURL
            )
            
            userName = editingName
            userBio = editingBio
            
            generateHapticFeedback(style: .success)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showingSaveConfirmation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showingSaveConfirmation = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    dismiss()
                }
            }
            
        } catch {
            print("❌ save profile error:", error.localizedDescription)
        }
    }
}

// MARK: - Bio Edit View (Standalone)

struct BioEditView: View {
    @Binding var bio: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    private let maxLength = 160
    
    var body: some View {
        VStack(spacing: 0) {
            // 文字数インジケーター
            HStack {
                Spacer()
                Text("\(bio.count)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(bio.count > maxLength ? .red : .secondary)
                    .padding(.trailing)
                    .padding(.top, 8)
            }
            
            TextField("自己紹介を入力", text: $bio, axis: .vertical)
                .focused($isFocused)
                .padding()
                .font(.body)
                .lineLimit(3...10)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("自己紹介")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    dismiss()
                }
                .fontWeight(.medium)
            }
        }
        .onAppear {
            isFocused = true
        }
        .onChange(of: bio) { newValue in
            if newValue.count > maxLength {
                bio = String(newValue.prefix(maxLength))
            }
        }
    }
}

// MARK: - Haptic Helper

func generateHapticFeedback(style: UINotificationFeedbackGenerator.FeedbackType? = nil) {
    if let style = style {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    } else {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileEditView(
            userName: .constant("テストユーザー"),
            userBio: .constant("こんにちは！AIsnsを楽しんでいます。"),
            avatarImage: .constant(nil)
        )
    }
}
