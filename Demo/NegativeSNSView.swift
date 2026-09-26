//
//  NegativeSNSView.swift
//  AIsns
//
//  Created by Apple on 2026/01/30.
//

import SwiftUI

// MARK: - Models
struct NegativePost: Identifiable {
    let id = UUID()
    let username: String
    let userHandle: String
    let avatarColor: Color
    let content: String
    let timeAgo: String
    let likes: Int
    let comments: Int
    let reposts: Int
    let category: NegativeCategory
}

enum NegativeCategory: String, CaseIterable {
    case comparison = "比較"
    case brag = "自慢"
    case complaint = "愚痴"
    case toxic = "批判"
    case fomo = "FOMO"
}

// MARK: - Sample Data
let negativePosts: [NegativePost] = [
    NegativePost(
        username: "感情電池切れ",
        userHandle: "@no_emotion_left",
        avatarColor: .gray,
        content: "楽しいも悲しいも薄味になってきた。感情の解像度どこいった？",
        timeAgo: "3分前",
        likes: 6542,
        comments: 1503,
        reposts: 488,
        category: .complaint
    ),
    NegativePost(
        username: "存在ログ薄め",
        userHandle: "@fade_presence",
        avatarColor: .blue,
        content: "今日も生きたっていうより、今日も終了したって感覚。",
        timeAgo: "6分前",
        likes: 7120,
        comments: 1821,
        reposts: 601,
        category: .complaint
    ),
    NegativePost(
        username: "意味探索失敗",
        userHandle: "@no_meaning",
        avatarColor: .purple,
        content: "何のために頑張るのか分からないまま、とりあえず時間だけ進んでる。",
        timeAgo: "10分前",
        likes: 5833,
        comments: 1290,
        reposts: 372,
        category: .complaint
    ),
    NegativePost(
        username: "透明人間気分",
        userHandle: "@invisible_mode",
        avatarColor: .black,
        content: "いてもいなくても変わらない感覚が続くと、自分の輪郭がぼやけてくる。",
        timeAgo: "14分前",
        likes: 6891,
        comments: 1702,
        reposts: 520,
        category: .complaint
    ),
    NegativePost(
        username: "回復待ち状態",
        userHandle: "@loading_life",
        avatarColor: .cyan,
        content: "何かが回復するの待ってるけど、何を待ってるのか自分でも分からない。",
        timeAgo: "18分前",
        likes: 5410,
        comments: 1204,
        reposts: 338,
        category: .complaint
    ),
    NegativePost(
        username: "夜思考ループ",
        userHandle: "@night_loop",
        avatarColor: .indigo,
        content: "昼は平気なフリできるのに、夜になると全部ノイズ大きくなるのやめてほしい。",
        timeAgo: "22分前",
        likes: 7782,
        comments: 2103,
        reposts: 690,
        category: .complaint
    ),
    NegativePost(
        username: "希望低電力",
        userHandle: "@low_hope",
        avatarColor: .brown,
        content: "期待すると疲れるから、最初から期待値下げて生きるモード。",
        timeAgo: "27分前",
        likes: 6033,
        comments: 1422,
        reposts: 455,
        category: .complaint
    ),
    NegativePost(
        username: "感覚鈍化中",
        userHandle: "@numb_state",
        avatarColor: .green,
        content: "何も感じないのが一番楽になってきたの、ちょっと怖い。",
        timeAgo: "31分前",
        likes: 7211,
        comments: 1899,
        reposts: 577,
        category: .complaint
    ),
    NegativePost(
        username: "思考ノイズ過多",
        userHandle: "@mind_noise",
        avatarColor: .pink,
        content: "頭の中ずっと会議してるのに、結論はいつも『分からない』。",
        timeAgo: "36分前",
        likes: 5620,
        comments: 1233,
        reposts: 340,
        category: .complaint
    ),
    NegativePost(
        username: "ただの通過点",
        userHandle: "@just_passing",
        avatarColor: .teal,
        content: "人生のメインストーリー始まる前にエンディング迎えそうな感覚ある。",
        timeAgo: "42分前",
        likes: 6888,
        comments: 1701,
        reposts: 509,
        category: .complaint
    ),

]


// MARK: - Sample Data
//let negativePosts: [NegativePost] = [
//    NegativePost(
//        username: "港区女子まりな",
//        userHandle: "@marina_minato",
//        avatarColor: .purple,
//        content: "また友達が結婚した...私だけ取り残されてる感じ。28歳なのにまだ彼氏すらいない。もう終わりかも。",
//        timeAgo: "5分前",
//        likes: 2341,
//        comments: 567,
//        reposts: 123,
//        category: .comparison
//    ),
//    NegativePost(
//        username: "社畜たろう",
//        userHandle: "@shachiku_taro",
//        avatarColor: .gray,
//        content: "同期が昇進したらしい。俺より仕事できないのに。結局コネがある奴が勝つんだよな。この会社終わってる。",
//        timeAgo: "8分前",
//        likes: 4521,
//        comments: 892,
//        reposts: 234,
//        category: .complaint
//    ),
//    NegativePost(
//        username: "毒舌レビュアー",
//        userHandle: "@dokuzetu_review",
//        avatarColor: .red,
//        content: "あの新作映画見たけどマジでゴミ。金返せレベル。これ褒めてる奴センスなさすぎ。映画見る目養った方がいいよ😂",
//        timeAgo: "15分前",
//        likes: 12043,
//        comments: 2341,
//        reposts: 892,
//        category: .toxic
//    ),
//    NegativePost(
//        username: "ママ友地獄",
//        userHandle: "@mamatomojigoku",
//        avatarColor: .green,
//        content: "隣のクラスのママ、また私の悪口言ってたらしい。子供の前では仲良くしてたのに最悪。信じられる人いない。",
//        timeAgo: "25分前",
//        likes: 3421,
//        comments: 892,
//        reposts: 156,
//        category: .complaint
//    ),
//    NegativePost(
//        username: "リア充爆発しろ",
//        userHandle: "@riaju_bakuhatsu",
//        avatarColor: .brown,
//        content: "TLがみんなBBQとかフェスの写真ばっかり...誘われてない自分が惨めになる。土日は部屋で一人。",
//        timeAgo: "30分前",
//        likes: 8923,
//        comments: 1234,
//        reposts: 567,
//        category: .fomo
//    ),
//    NegativePost(
//        username: "承認欲求モンスター",
//        userHandle: "@shounin_monster",
//        avatarColor: .indigo,
//        content: "この前の投稿全然いいねつかなかった...私の存在価値って何？誰も見てくれてない気がする。消えたい。",
//        timeAgo: "35分前",
//        likes: 5678,
//        comments: 2341,
//        reposts: 123,
//        category: .comparison
//    ),
//    NegativePost(
//        username: "マウント女王",
//        userHandle: "@mount_queen",
//        avatarColor: .cyan,
//        content: "え、まだiPhone13使ってるの？w 私は発売日に最新機種買うけど、お金ない人は大変だね〜",
//        timeAgo: "40分前",
//        likes: 2341,
//        comments: 678,
//        reposts: 89,
//        category: .brag
//    ),
//    NegativePost(
//        username: "病みツイ常習犯",
//        userHandle: "@yami_tweet",
//        avatarColor: .gray,
//        content: "もう何もかもどうでもいい。誰も私のこと分かってくれない。生きてる意味が分からなくなってきた。",
//        timeAgo: "45分前",
//        likes: 4567,
//        comments: 1892,
//        reposts: 234,
//        category: .complaint
//    )
//]

// MARK: - Main View
struct NegativeSNSView: View {
    @State private var selectedTab = 0
    @State private var selectedPost: NegativePost?
    @State private var showingDetail = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // Tab Bar
                tabBarView

                // Content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(negativePosts) { post in
                            PostCell(post: post)
                                .onTapGesture {
                                    selectedPost = post
                                    showingDetail = true
                                }

                            Divider()
                                .background(Color.black.opacity(0.08))
                        }
                    }
                }
            }
            .background(Color.white)
            .navigationDestination(isPresented: $showingDetail) {
                if let post = selectedPost {
                    PostDetailView1(post: post)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var headerView: some View {
        HStack {
            Circle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                )

            Spacer()

            Text("SNS")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            Image(systemName: "gearshape")
                .foregroundColor(.black)
                .font(.system(size: 20))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var tabBarView: some View {
        HStack(spacing: 0) {
            TabButton1(title: "おすすめ", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton1(title: "フォロー中", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Tab Button
struct TabButton1: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .black : .gray)

                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}

// MARK: - Post Cell
struct PostCell: View {
    let post: NegativePost

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(post.avatarColor.gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(post.username.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                // User info
                HStack(spacing: 4) {
                    Text(post.username)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)

                    Text(post.userHandle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Text("·")
                        .foregroundColor(.gray)

                    Text(post.timeAgo)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                // Content
                Text(post.content)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .lineSpacing(4)
                    .padding(.top, 4)

                // Actions
                HStack(spacing: 0) {
                    ActionButton2(icon: "bubble.left", count: post.comments)
                    Spacer()
                    ActionButton2(icon: "arrow.2.squarepath", count: post.reposts)
                    Spacer()
                    ActionButton2(icon: "heart", count: post.likes)
                    Spacer()
                    ActionButton2(icon: "square.and.arrow.up", count: nil)
                }
                .padding(.top, 12)
                .padding(.trailing, 40)
            }
        }
        .padding(16)
        .background(Color.white)
    }

    private func categoryColor(_ category: NegativeCategory) -> Color {
        switch category {
        case .comparison: return .purple
        case .brag: return .orange
        case .complaint: return .gray
        case .toxic: return .red
        case .fomo: return .blue
        }
    }
}

// MARK: - Action Button
struct ActionButton2: View {
    let icon: String
    let count: Int?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)

            if let count = count {
                Text(formatCount(count))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1f万", Double(count) / 10000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

// MARK: - Post Detail View
struct PostDetailView1: View {
    let post: NegativePost
    @Environment(\.dismiss) private var dismiss
    @State private var replyText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Main Post
                    mainPostView

                    Divider()
                        .background(Color.black.opacity(0.08))

                    // Stats
                    statsView

                    Divider()
                        .background(Color.black.opacity(0.08))

                    // Action Buttons
                    actionButtonsView

                    Divider()
                        .background(Color.black.opacity(0.08))

                    // Negative Comments Section
                    commentsSection
                }
            }

            // Reply Input
            replyInputView
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("投稿")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .preferredColorScheme(.light)
    }

    private var mainPostView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack(spacing: 12) {
                Circle()
                    .fill(post.avatarColor.gradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(post.username.prefix(1)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    Text(post.userHandle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }

            // Content
            Text(post.content)
                .font(.system(size: 18))
                .foregroundColor(.black)
                .lineSpacing(6)

            // Timestamp
            Text("午後3:42 · 2025年1月30日")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding(16)
    }

    private var statsView: some View {
        HStack(spacing: 20) {
            StatItem1(count: post.reposts, label: "リポスト")
            StatItem1(count: post.comments, label: "引用")
            StatItem1(count: post.likes, label: "いいね")
            StatItem1(count: 234, label: "ブックマーク")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var actionButtonsView: some View {
        HStack(spacing: 0) {
            ForEach(["bubble.left", "arrow.2.squarepath", "heart", "bookmark", "square.and.arrow.up"], id: \.self) { icon in
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(.vertical, 12)
    }

    private var commentsSection: some View {
        VStack(spacing: 0) {
            ForEach(negativeComments, id: \.username) { comment in
                CommentCell(comment: comment)
                Divider()
                    .background(Color.black.opacity(0.08))
            }
        }
    }

    private var replyInputView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                )

            TextField("返信をポスト", text: $replyText)
                .font(.system(size: 15))
                .foregroundColor(.black)

            Button(action: {}) {
                Text("返信")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
            .opacity(replyText.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5),
            alignment: .top
        )
    }

    private func categoryColor(_ category: NegativeCategory) -> Color {
        switch category {
        case .comparison: return .purple
        case .brag: return .orange
        case .complaint: return .gray
        case .toxic: return .red
        case .fomo: return .blue
        }
    }
}

// MARK: - Stat Item
struct StatItem1: View {
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Comment Cell
struct NegativeComment {
    let username: String
    let userHandle: String
    let avatarColor: Color
    let content: String
    let timeAgo: String
    let likes: Int
}

let negativeComments: [NegativeComment] = [
    NegativeComment(
        username: "アンチ1号",
        userHandle: "@anti_ichi",
        avatarColor: .red,
        content: "はいはい、また自慢ですか。承認欲求強すぎて引くわ。",
        timeAgo: "1分前",
        likes: 234
    ),
    NegativeComment(
        username: "正義マン",
        userHandle: "@seigi_man",
        avatarColor: .blue,
        content: "こういう投稿見るたびに日本の未来が心配になる。浅すぎ。",
        timeAgo: "3分前",
        likes: 567
    ),
    NegativeComment(
        username: "嫉妬の塊",
        userHandle: "@shitto_katamari",
        avatarColor: .green,
        content: "羨ましすぎて吐きそう。なんで私の人生こんなにつまらないんだろう。",
        timeAgo: "5分前",
        likes: 123
    ),
    NegativeComment(
        username: "論破厨",
        userHandle: "@ronpa_chu",
        avatarColor: .orange,
        content: "いや、それ論理破綻してない？ちょっと考えれば分かることなのに。知性を感じない。",
        timeAgo: "8分前",
        likes: 892
    ),
    NegativeComment(
        username: "傍観者",
        userHandle: "@boukansha",
        avatarColor: .purple,
        content: "コメント欄地獄で草。やっぱSNSって人の醜い部分引き出すよね。",
        timeAgo: "12分前",
        likes: 1234
    )
]

struct CommentCell: View {
    let comment: NegativeComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(comment.avatarColor.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(comment.username.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)

                    Text(comment.userHandle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    Text("·")
                        .foregroundColor(.gray)

                    Text(comment.timeAgo)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .lineSpacing(3)

                HStack(spacing: 24) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 14))
                        Text("返信")
                            .font(.system(size: 12))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                        Text("\(comment.likes)")
                            .font(.system(size: 12))
                    }
                }
                .foregroundColor(.gray)
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Preview
#Preview {
    NegativeSNSView()
}
