import SwiftUI

// MARK: - Models
struct FlamePost: Identifiable {
    let id = UUID()
    let user: FlameUser
    let content: String
    let time: String
    let likes: Int
    let retweets: Int
    let replies: Int
    let isControversial: Bool
    let replyTo: String?
}

struct FlameUser: Identifiable {
    let id = UUID()
    let name: String
    let handle: String
    let avatar: String
    let isVerified: Bool
    let followerCount: String
}

// MARK: - Main View
struct FlameWarView: View {
    @State private var posts: [FlamePost] = []
    @State private var showFireEffect = true
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // 炎上背景
            LinearGradient(
                colors: [
                    Color.black,
                    Color.red.opacity(0.3),
                    Color.orange.opacity(0.2),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            
            VStack(spacing: 0) {
                // ヘッダー
                flameHeader
                
                // 炎上警告バナー
//                warningBanner
                
                // 投稿リスト
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(samplePosts) { post in
                            FlamePostCard(post: post)
                            Divider()
                                .background(Color.red.opacity(0.3))
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    var flameHeader: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.title2)
            
            Spacer()
            
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    pulseAnimation = true
                }
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .font(.title2)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
    }
    
    // MARK: - Warning Banner
    var warningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
            Text("このスレッドは議論が過熱しています")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text("詳細")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.red.opacity(0.2))
        .overlay(
            Rectangle()
                .stroke(Color.red.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Sample Data
    var samplePosts: [FlamePost] {
        let userA = FlameUser(name: "炎上太郎", handle: "@flame_taro", avatar: "😤", isVerified: true, followerCount: "12.5万")
        let userB = FlameUser(name: "反論花子", handle: "@hanron_hanako", avatar: "😡", isVerified: false, followerCount: "8.3万")
        let userC = FlameUser(name: "野次馬くん", handle: "@yajiuma_kun", avatar: "🍿", isVerified: false, followerCount: "2.1万")
        let userD = FlameUser(name: "正義マン", handle: "@seigi_man", avatar: "⚔️", isVerified: true, followerCount: "45.2万")
        let userE = FlameUser(name: "まとめ屋", handle: "@matome_ya", avatar: "📝", isVerified: false, followerCount: "5.7万")
        
        return [
            FlamePost(user: userA, content: "いい加減にしろよ！お前の言ってることは全部間違ってる！証拠も出さずに人を批判するな！", time: "2分", likes: 1523, retweets: 892, replies: 456, isControversial: true, replyTo: nil),
            
            FlamePost(user: userB, content: "は？？？こっちは証拠出してるんですけど？？ちゃんと読んでから発言してください。読解力ないんですか？", time: "1分", likes: 2341, retweets: 1205, replies: 789, isControversial: true, replyTo: "@flame_taro"),
            
            FlamePost(user: userC, content: "🍿🍿🍿\nこれは伸びる\nスクショ保存した", time: "30秒", likes: 5621, retweets: 2103, replies: 234, isControversial: false, replyTo: nil),
            
            FlamePost(user: userA, content: "読解力の話にすり替えるな！\n論点ずらしの典型だろ！\n\nもう一度言う、お前の主張には根拠がない！", time: "20秒", likes: 1892, retweets: 943, replies: 567, isControversial: true, replyTo: "@hanron_hanako"),
            
            FlamePost(user: userD, content: "横から失礼します。\n\nどちらも落ち着いてください。\n議論と罵倒は違います。\n\nまず事実関係を整理しましょう。", time: "15秒", likes: 8923, retweets: 3421, replies: 892, isControversial: false, replyTo: nil),
            
            FlamePost(user: userB, content: "@seigi_man 正義マン出たwww\nいつも上から目線で仲裁ぶるの好きですね〜\n\n当事者でもないのに口出さないでもらえます？", time: "10秒", likes: 3245, retweets: 1567, replies: 678, isControversial: true, replyTo: "@seigi_man"),
            
            FlamePost(user: userE, content: "【速報】炎上太郎 vs 反論花子、ついに正義マンも参戦で三つ巴に\n\nまとめ作成中...\n\n続報をお待ちください", time: "5秒", likes: 12453, retweets: 5678, replies: 1234, isControversial: false, replyTo: nil),
        ]
    }
}

// MARK: - Post Card
struct FlamePostCard: View {
    let post: FlamePost
    @State private var isShaking = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reply indicator
            if let replyTo = post.replyTo {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption2)
                    Text("\(replyTo) に返信")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                .padding(.leading, 52)
            }
            
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            post.isControversial ?
                            LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 48)
                    
                    Text(post.user.avatar)
                        .font(.title2)
                }
                .modifier(ShakeEffect(shakes: isShaking && post.isControversial ? 2 : 0))
                .onAppear {
                    if post.isControversial {
                        withAnimation(.easeInOut(duration: 0.3).repeatForever()) {
                            isShaking = true
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // User info
                    HStack(spacing: 4) {
                        Text(post.user.name)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if post.user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Text(post.user.handle)
                            .foregroundColor(.gray)
                        
                        Text("・\(post.time)")
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                    
                    // Content
                    Text(post.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineSpacing(4)
                    
                    // Actions
                    HStack(spacing: 0) {
                        ActionButton1(icon: "bubble.left", count: post.replies, color: .gray)
                        Spacer()
                        ActionButton1(icon: "arrow.2.squarepath", count: post.retweets, color: .green)
                        Spacer()
                        ActionButton1(icon: "heart", count: post.likes, color: .pink)
                        Spacer()
                        ActionButton1(icon: "square.and.arrow.up", count: nil, color: .gray)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(
            post.isControversial ?
            Color.red.opacity(0.1) :
            Color.clear
        )
    }
}

// MARK: - Action Button
struct ActionButton1: View {
    let icon: String
    let count: Int?
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
            if let count = count {
                Text(formatCount(count))
                    .font(.caption)
            }
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Flame Effect
struct FlameEffectView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<15) { i in
                FlameParticle(index: i, phase: phase)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

struct FlameParticle: View {
    let index: Int
    let phase: CGFloat
    
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: CGFloat.random(in: 20...40)))
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange, .red],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .offset(
                x: CGFloat(index * 30 - 200) + sin(phase * .pi * 2 + CGFloat(index)) * 10,
                y: -phase * 100 + CGFloat(index % 3) * 20
            )
            .opacity(1 - phase)
            .blur(radius: phase * 3)
    }
}

// MARK: - Shake Effect
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: sin(shakes * .pi * 2) * 3, y: 0))
    }
}

// MARK: - Preview
struct FlameWarView_Previews: PreviewProvider {
    static var previews: some View {
        FlameWarView()
    }
}
