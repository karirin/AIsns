//
//  SNSProfileView.swift
//  AIsns
//
//  Created by Apple on 2026/01/20.
//

import SwiftUI
import PhotosUI

// MARK: - Profile Data Model
class ProfileViewModel: ObservableObject {
    @Published var username: String = "user_name"
    @Published var displayName: String = "Display Name"
    @Published var bio: String = "ここに自己紹介文が入ります 🎨✨"
    @Published var followingCount: Int = 128
    @Published var followersCount: Int = 1024
    @Published var postsCount: Int = 42
    @Published var profileImage: UIImage? = nil
    @Published var isCountUpEnabled: Bool = false
    
    private var countUpTimer: Timer?
    
    func startCountUp() {
        guard isCountUpEnabled else { return }
        countUpTimer?.invalidate()
        countUpTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isCountUpEnabled else {
                self?.countUpTimer?.invalidate()
                return
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                self.followersCount += Int.random(in: 1...5)
            }
        }
    }
    
    func stopCountUp() {
        countUpTimer?.invalidate()
        countUpTimer = nil
    }
    
    deinit {
        countUpTimer?.invalidate()
    }
}

// MARK: - Main Profile View
struct SNSProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Background
                    headerSection
                        .padding(.top, -60) // ナビゲーションバー分を上にずらす
                    
                    // Profile Content
                    VStack(spacing: 20) {
                        // Profile Image
                        profileImageSection
                            .offset(y: -50)
                        
                        // User Info
                        userInfoSection
                            .offset(y: -30)
                        
                        // Stats
                        statsSection
                            .offset(y: -20)
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Posts Grid Placeholder
                        postsGridSection
                    }
                    .padding(.horizontal)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditProfileSheet(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Settings Button
    private var settingsButton: some View {
        Button {
            showEditSheet = true
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8),
                    Color(red: 0.6, green: 0.3, blue: 0.9),
                    Color(red: 0.8, green: 0.4, blue: 0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Pattern Overlay
            GeometryReader { geo in
                Canvas { context, size in
                    for _ in 0..<20 {
                        let x = CGFloat.random(in: 0...size.width)
                        let y = CGFloat.random(in: 0...size.height)
                        let circle = Path(ellipseIn: CGRect(x: x, y: y, width: 50, height: 50))
                        context.fill(circle, with: .color(.white.opacity(0.05)))
                    }
                }
            }
        }
        .frame(height: 240) // SafeArea分を加算
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
            
            if let image = viewModel.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    }
            }
            
            // Camera Button
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Circle()
                    .fill(.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.purple)
                    }
            }
            .offset(x: 35, y: 35)
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.profileImage = image
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(viewModel.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.blue)
                    .font(.subheadline)
            }
            
            Text("@\(viewModel.username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(viewModel.bio)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.top, 4)
        }
        .animation(.spring(response: 0.3), value: viewModel.isCountUpEnabled)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItem(value: viewModel.postsCount, label: "投稿")
            
            Divider()
                .frame(height: 40)
            
            StatItem(value: viewModel.followersCount, label: "フォロワー")
            
            Divider()
                .frame(height: 40)
            
            StatItem(value: viewModel.followingCount, label: "フォロー中")
        }
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button {
                // Follow action
            } label: {
                Text("フォロー")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
            }
            
            Button {
                // Message action
            } label: {
                Text("メッセージ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    }
            }
            
            Button {
                // Share action
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    }
            }
        }
    }
    
    // MARK: - Posts Grid Section
    private var postsGridSection: some View {
        VStack(spacing: 16) {
            // Tab Bar
            HStack {
                ForEach(["grid", "play.square.stack", "bookmark"], id: \.self) { icon in
                    Spacer()
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(icon == "grid" ? .primary : .secondary)
                    Spacer()
                }
            }
            .padding(.vertical, 12)
            .background {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                }
            }
            
            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                ForEach(0..<9, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: Double(index) / 9.0, saturation: 0.6, brightness: 0.9),
                                    Color(hue: Double(index) / 9.0 + 0.1, saturation: 0.7, brightness: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }
}

// MARK: - Stat Item Component
struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatNumber(value))
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatNumber(_ num: Int) -> String {
        return "\(num)"
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("プロフィール情報") {
                    TextField("表示名", text: $viewModel.displayName)
                    TextField("ユーザー名", text: $viewModel.username)
                    TextField("自己紹介", text: $viewModel.bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("フォロー・フォロワー") {
                    HStack {
                        Text("フォロー中")
                        Spacer()
                        TextField("0", value: $viewModel.followingCount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Stepper("", value: $viewModel.followingCount, in: 0...999999)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("フォロワー")
                        Spacer()
                        TextField("0", value: $viewModel.followersCount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Stepper("", value: $viewModel.followersCount, in: 0...999999)
                            .labelsHidden()
                    }
                    
                    HStack {
                        Text("投稿数")
                        Spacer()
                        TextField("0", value: $viewModel.postsCount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Stepper("", value: $viewModel.postsCount, in: 0...999999)
                            .labelsHidden()
                    }
                }
                
                Section {
                    Toggle(isOn: $viewModel.isCountUpEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("カウントアップ")
                                .font(.body)
                            Text("ONにするとフォロワー数が自動で増加します")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.purple)
                    .onChange(of: viewModel.isCountUpEnabled) { newValue in
                        if newValue {
                            viewModel.startCountUp()
                        } else {
                            viewModel.stopCountUp()
                        }
                    }
                } header: {
                    Text("特殊設定")
                } footer: {
                    Text("カウントアップをONにすると、フォロワー数が0.5秒ごとに1〜5ずつ増加します。")
                }
                
                Section {
                    Button(role: .destructive) {
                        viewModel.profileImage = nil
                    } label: {
                        HStack {
                            Spacer()
                            Text("プロフィール画像をリセット")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.profileImage == nil)
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview
#Preview {
    SNSProfileView()
}
