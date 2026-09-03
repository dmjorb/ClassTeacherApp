import SwiftUI
import UIKit

// MARK: - iOS 原生设计系统
// 遵循 Apple Human Interface Guidelines
enum AppTheme {
    // MARK: - 颜色（使用系统语义色）
    enum Colors {
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
        static let tertiaryGroupedBackground = Color(.tertiarySystemGroupedBackground)
        
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(.tertiaryLabel)
        
        static let separator = Color(.separator)
        static let opaqueSeparator = Color(.opaqueSeparator)
        
        static let accent = Color.accentColor
        static let blue = Color(.systemBlue)
        static let green = Color(.systemGreen)
        static let orange = Color(.systemOrange)
        static let red = Color(.systemRed)
        static let purple = Color(.systemPurple)
        static let pink = Color(.systemPink)
        static let yellow = Color(.systemYellow)
        static let mint = Color(.systemMint)
        static let cyan = Color(.systemCyan)
        static let teal = Color(.systemTeal)
        static let indigo = Color(.systemIndigo)
        static let brown = Color(.systemBrown)
        static let gray = Color(.systemGray)
        static let gray2 = Color(.systemGray2)
        static let gray3 = Color(.systemGray3)
        static let gray4 = Color(.systemGray4)
        static let gray5 = Color(.systemGray5)
        static let gray6 = Color(.systemGray6)
    }
    
    // MARK: - 字体（使用系统字体样式）
    enum Fonts {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - 间距（使用系统标准间距）
    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }
    
    // MARK: - 圆角（使用系统标准圆角）
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let continuous: CGFloat = 12
    }
}

// MARK: - 通用组件
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.xSmall) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.Colors.accent)
            }
            Text(title)
                .font(AppTheme.Fonts.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.xSmall)
    }
}

// 系统风格的统计卡片
struct StatCard: View {
    let value: String
    let label: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xSmall) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(AppTheme.Fonts.title2.weight(.bold))
                .foregroundColor(AppTheme.Colors.primaryText)
            Text(label)
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.medium)
        .background(AppTheme.Colors.secondaryGroupedBackground)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// 系统风格的功能入口按钮
struct FeatureButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.15))
                    .cornerRadius(AppTheme.CornerRadius.medium)
                Text(title)
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(.plain)
    }
}

// 学生头像（系统风格）
struct StudentAvatar: View {
    let name: String
    var size: CGFloat = 48
    var color: Color = AppTheme.Colors.orange
    
    var body: some View {
        Circle()
            .fill(color.gradient)
            .frame(width: size, height: size)
            .overlay(
                Text(String(name.prefix(1)))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            )
    }
}

// 系统风格的空状态
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.gray3)
            Text(title)
                .font(AppTheme.Fonts.title2.weight(.semibold))
                .foregroundColor(AppTheme.Colors.primaryText)
            Text(message)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxLarge)
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Label(buttonTitle, systemImage: "plus.circle.fill")
                        .font(AppTheme.Fonts.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.large)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .background(AppTheme.Colors.accent)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 系统风格的标签
struct PillTag: View {
    let title: String
    var color: Color = AppTheme.Colors.accent
    
    var body: some View {
        Text(title)
            .font(AppTheme.Fonts.caption.weight(.medium))
            .foregroundColor(color)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(.greatestFiniteMagnitude)
    }
}
