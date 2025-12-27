//
//  UserProfileView.swift
//  AIsns
//
//  Created by Apple on 2025/12/27.
//

import SwiftUI

struct UserProfileView: View {
    @State private var userName: String = "あなた"
    @State private var userBio: String = ""
    @State private var avatarImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingEditSheet = false
    @State private var isLoadingImage = false
    
    private let avatarSize: CGFloat = 100
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // アバターセクション
                    avatarSection
                    
                    // プロフィール情報
                    profileInfoSection
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // 統計情報
                    statsSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Text("編集")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                NavigationStack {
                    UserProfileEditView(
                        userName: $userName,
                        userBio: $userBio,
                        avatarImage: $avatarImage
                    )
                }
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景のグラデーションリング
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.7, blue: 1.0).opacity(0.3),
                                Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: avatarSize + 12, height: avatarSize + 12)
                
                avatarView
            }
        }
        .padding(.top, 24)
    }
    
    private var avatarView: some View {
        Group {
            if isLoadingImage {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        ProgressView()
                            .tint(.gray)
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
                                Color(red: 0.2, green: 0.7, blue: 1.0),
                                Color(red: 0.5, green: 0.4, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Profile Info Section
    
    private var profileInfoSection: some View {
        VStack(spacing: 12) {
            // 名前
            Text(userName)
                .font(.title2)
                .fontWeight(.bold)
            
            // 自己紹介
            if !userBio.isEmpty {
                Text(userBio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("統計")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                StatRow(label: "投稿", value: "0")
                
                Divider()
                    .padding(.leading, 16)
                
                StatRow(label: "フォロー中", value: "0")
                
                Divider()
                    .padding(.leading, 16)
                
                StatRow(label: "いいね", value: "0")
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Edit View

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
    
    init(userName: Binding<String>, userBio: Binding<String>, avatarImage: Binding<UIImage?>) {
        self._userName = userName
        self._userBio = userBio
        self._avatarImage = avatarImage
        self._editingName = State(initialValue: userName.wrappedValue)
        self._editingBio = State(initialValue: userBio.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // プロフィール画像エリア
                    VStack(spacing: 12) {
                        Button(action: { showingImagePicker = true }) {
                            Group {
                                if isLoadingImage {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            ProgressView()
                                        )
                                } else if let avatarImage = avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 4)
                                        )
                                        .shadow(radius: 5)
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.2, green: 0.7, blue: 1.0),
                                                    Color(red: 0.5, green: 0.4, blue: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                        
                        Text("写真を変更")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    
                    // 基本情報セクション
                    VStack(spacing: 0) {
                        Text("基本情報")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            // 名前
                            HStack {
                                Text("名前")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                TextField("", text: $editingName)
                                    .multilineTextAlignment(.trailing)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.clear)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // 自己紹介
                            NavigationLink {
                                BioEditView(bio: $editingBio)
                            } label: {
                                HStack {
                                    Text("自己紹介")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text(editingBio.isEmpty ? "追加" : editingBio)
                                        .font(.subheadline)
                                        .foregroundColor(editingBio.isEmpty ? .secondary : .primary)
                                        .lineLimit(1)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGray6))
            
            // トースト通知
            if showingSaveConfirmation {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("保存しました")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.85))
                    )
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: showingSaveConfirmation)
            }
        }
        .navigationTitle("プロフィールを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    saveChanges()
                }
                .foregroundColor(.primary)
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerWithCrop(selectedImage: $avatarImage)
        }
    }
    
    private func saveChanges() {
        userName = editingName
        userBio = editingBio
        
        // 保存完了の通知を表示
        withAnimation {
            showingSaveConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingSaveConfirmation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// MARK: - Bio Edit View

struct BioEditView: View {
    @Binding var bio: String
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("自己紹介を入力", text: $bio, axis: .vertical)
                .focused($isFocused)
                .padding()
                .font(.body)
                .lineLimit(3...10)
            
            Spacer()
        }
        .navigationTitle("自己紹介")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    dismiss()
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    UserProfileView()
}
