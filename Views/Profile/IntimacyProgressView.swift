import SwiftUI

struct IntimacyProgressView: View {
    let oshi: OshiCharacter
    var compact = false

    private var nextReward: String {
        switch oshi.intimacyLevel {
        case 1: return "次のレベルで少しくだけた話し方に"
        case 2: return "次のレベルで呼び方がもっと親しく"
        case 3: return "次のレベルで特別なセリフを解放"
        case 4: return "次のレベルで最高の関係へ"
        default: return "すべての親密度ごほうびを解放済み"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            HStack {
                Label("Lv.\(oshi.intimacyLevel) \(oshi.intimacyTitle)", systemImage: "heart.circle.fill")
                    .font(compact ? AppTypography.captionMedium : AppTypography.subheadlineMedium)
                    .foregroundColor(AppColors.pink)
                Spacer()
                if let remaining = oshi.interactionsUntilNextLevel {
                    Text("あと\(remaining)")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            ProgressView(value: oshi.intimacyProgress)
                .tint(AppColors.pink)

            if !compact {
                Text(nextReward)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("親密度レベル\(oshi.intimacyLevel)、\(oshi.intimacyTitle)")
    }
}
