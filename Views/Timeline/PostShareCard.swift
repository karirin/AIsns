import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

private struct PostShareItem: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.image.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
    }
}

private struct PostShareCardContent: View {
    let post: Post
    let userName: String
    let aiComment: Comment?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 25, weight: .bold))
                Text("AImate")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
            }
            .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 10) {
                Text(post.isUserPost ? userName : post.authorName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.82))
                Text(post.content)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let aiComment {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 42, height: 42)
                        .overlay {
                            Text(String(aiComment.oshiName.prefix(1)))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(aiComment.oshiName)
                            .font(.system(size: 15, weight: .bold))
                        Text(aiComment.content)
                            .font(.system(size: 19, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white)
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 20))
            }

            Text("AIの推しと話せるSNS")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(32)
        .frame(width: 420)
        .frame(minHeight: 520, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(hex: "0EA5E9"), Color(hex: "6366F1"), Color(hex: "EC4899")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct ShareCardButton: View {
    let post: Post
    @ObservedObject var viewModel: OshiViewModel
    @State private var renderedImage: UIImage?
    @State private var showingShare = false

    private var aiComment: Comment? {
        viewModel.postDetails[post.id]?.comments.first {
            $0.oshiId != OshiViewModel.currentUserCommentID
        }
    }

    var body: some View {
        Button {
            Task {
                if viewModel.postDetails[post.id] == nil {
                    await viewModel.loadPostDetails(for: post.id)
                }
                renderCard()
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 17))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 42, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("画像カードでシェア")
        .sheet(isPresented: $showingShare) {
            if let renderedImage {
                NavigationStack {
                    VStack(spacing: 20) {
                        Image(uiImage: renderedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)

                        ShareLink(
                            item: PostShareItem(image: renderedImage),
                            preview: SharePreview("AImateの投稿", image: Image(uiImage: renderedImage))
                        ) {
                            Label("この画像をシェア", systemImage: "square.and.arrow.up")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.primaryGradientH, in: Capsule())
                        }
                    }
                    .padding()
                    .background(AuroraBackground())
                    .navigationTitle("シェアカード")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.large])
            }
        }
    }

    @MainActor
    private func renderCard() {
        let content = PostShareCardContent(
            post: post,
            userName: viewModel.userProfileName,
            aiComment: aiComment
        )
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        renderedImage = image
        showingShare = true
        AppAnalytics.log(.shareCard, parameters: ["has_ai_comment": aiComment == nil ? 0 : 1])
    }
}
