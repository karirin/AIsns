import SwiftUI
import PhotosUI

// MARK: - Models
struct Post1: Identifiable {
    let id = UUID()
    let username: String
    let userAvatar: String
    var image: UIImage?
    let caption: String
    let subCaption: String
    let likes: Int
    let comments: Int
    let timeAgo: String
    let isLiked: Bool
}

// MARK: - Main View
@available(iOS 17.0, *)
struct KiraKiraSNSView: View {
    @State private var selectedTab: Int = 0
    @State private var showSparkles: Bool = true
    
    @State private var posts: [Post1] = [
        Post1(username: "beach_lover", userAvatar: "person.circle.fill", image: nil, caption: "BBQ NIGHT!", subCaption: "✨ Good food & good company! ✨🤍", likes: 1247, comments: 89, timeAgo: "2時間前", isLiked: true),
        Post1(username: "summer_vibes", userAvatar: "person.circle.fill", image: nil, caption: "SUNSET MAGIC", subCaption: "🌅 Perfect evening with friends 🌴", likes: 892, comments: 45, timeAgo: "4時間前", isLiked: false),
        Post1(username: "party_queen", userAvatar: "person.circle.fill", image: nil, caption: "GIRLS NIGHT", subCaption: "💖 Making memories ✨", likes: 2103, comments: 156, timeAgo: "6時間前", isLiked: true),
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.90),
                    Color(red: 1.0, green: 0.98, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Feed
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        // Stories
                        storiesSection
                        
                        // Posts
                        ForEach($posts) { $post in
                            Post1CardView(post: $post, showSparkles: showSparkles)
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
            
            // Tab Bar
            VStack {
                Spacer()
                tabBarView
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("KiraKira")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.4),
                            Color(red: 1.0, green: 0.4, blue: 0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "plus.app")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                
                Button(action: {}) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "heart")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 2, y: -2)
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.9))
    }
    
    // MARK: - Stories Section
    private var storiesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Add Story
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 68, height: 68)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Text("追加")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                // Story items
                ForEach(0..<6) { index in
                    StoryItemView(
                        name: ["yuki", "miku", "hana", "ken", "sora", "rin"][index],
                        hasNew: index < 3
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Tab Bar
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(for: index))
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == index ? .orange : .gray)
                        
                        if selectedTab == index {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
        )
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "magnifyingglass"
        case 2: return "plus.circle.fill"
        case 3: return "play.rectangle"
        case 4: return "person.fill"
        default: return "house"
        }
    }
}

// MARK: - Story Item
struct StoryItemView: View {
    let name: String
    let hasNew: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Gradient ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: hasNew ? [
                                Color(red: 1.0, green: 0.8, blue: 0.3),
                                Color(red: 1.0, green: 0.5, blue: 0.3),
                                Color(red: 1.0, green: 0.3, blue: 0.5)
                            ] : [Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 68, height: 68)
                
                // Avatar placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.9, blue: 0.8),
                                Color(red: 1.0, green: 0.8, blue: 0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            Text(name)
                .font(.system(size: 11))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Post Card
@available(iOS 17.0, *)
struct Post1CardView: View {
    @Binding var post: Post1
    let showSparkles: Bool
    
    @State private var isLiked: Bool = false
    @State private var sparklePositions: [SparkleData] = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingImage: Bool = false
    
    init(post: Binding<Post1>, showSparkles: Bool) {
        self._post = post
        self.showSparkles = showSparkles
        self._isLiked = State(initialValue: post.wrappedValue.isLiked)
        self._sparklePositions = State(initialValue: Self.generateSparkles())
    }
    
    static func generateSparkles() -> [SparkleData] {
        (0..<25).map { _ in
            SparkleData(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.4...1.0),
                delay: Double.random(in: 0...2)
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // User header
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.system(size: 14, weight: .semibold))
                    Text(post.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Image with sparkles - Tappable to change image
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    // Image content
                    if let uiImage = post.image {
                        // User selected image
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    } else {
                        // Placeholder gradient
                        placeholderImageView
                    }
                    
                    // Sparkle overlay
                    if showSparkles {
                        GeometryReader { geo in
                            ForEach(sparklePositions.indices, id: \.self) { index in
                                SparkleView(data: sparklePositions[index])
                                    .position(
                                        x: sparklePositions[index].x * geo.size.width,
                                        y: sparklePositions[index].y * geo.size.height
                                    )
                            }
                        }
                    }
                    
                    // Caption overlay
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(post.caption)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                            
                            Text(post.subCaption)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                        }
                        .padding(.bottom, 40)
                        .opacity(0)
                    }
                    
                    // Loading indicator
                    if isLoadingImage {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                    
                    // Tap hint overlay
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 12))
                                Text("タップで画像変更")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(12)
                            .padding(12)
                            .opacity(0)
                        }
                        Spacer()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipped()
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            
            // Actions
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(isLiked ? .red : .primary)
                        .scaleEffect(isLiked ? 1.1 : 1.0)
                }
                
                Button(action: {}) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Likes and comments
            VStack(alignment: .leading, spacing: 6) {
                Text("\(post.likes.formatted())件のいいね")
                    .font(.system(size: 14, weight: .semibold))
                
                HStack(spacing: 4) {
                    Text(post.username)
                        .font(.system(size: 14, weight: .semibold))
                    Text(post.subCaption)
                        .font(.system(size: 14))
                        .lineLimit(1)
                }
                
                Text("\(post.comments)件のコメントを見る")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Placeholder Image
    private var placeholderImageView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.7),
                        Color(red: 1.0, green: 0.7, blue: 0.5),
                        Color(red: 0.95, green: 0.6, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                ZStack {
                    // Sun glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.9),
                                    Color.yellow.opacity(0.6),
                                    Color.orange.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 150
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(y: -50)
                    
                    // Palm tree silhouette
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.black.opacity(0.2))
                                .rotationEffect(.degrees(-30))
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                    
                    // People silhouettes
                    HStack(spacing: 15) {
                        ForEach(0..<5, id: \.self) { _ in
                            VStack {
                                Spacer()
                                Circle()
                                    .fill(Color.black.opacity(0.15))
                                    .frame(width: 30, height: 30)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: 25, height: 40)
                            }
                            .padding(.bottom, 80)
                        }
                    }
                }
            )
    }
    
    // MARK: - Load Image
    @MainActor
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoadingImage = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    post.image = uiImage
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
        
        isLoadingImage = false
    }
}

// MARK: - Sparkle Data
struct SparkleData {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let delay: Double
}

// MARK: - Sparkle View
struct SparkleView: View {
    let data: SparkleData
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: data.size))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color(red: 1.0, green: 0.95, blue: 0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.yellow.opacity(0.8), radius: 4)
            .opacity(isAnimating ? data.opacity : data.opacity * 0.3)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .animation(
                Animation
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(data.delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
struct KiraKiraSNSView_Previews: PreviewProvider {
    static var previews: some View {
        KiraKiraSNSView()
    }
}

// MARK: - App Entry Point
@available(iOS 17.0, *)
struct KiraKiraSNSApp: App {
    var body: some Scene {
        WindowGroup {
            KiraKiraSNSView()
        }
    }
}
