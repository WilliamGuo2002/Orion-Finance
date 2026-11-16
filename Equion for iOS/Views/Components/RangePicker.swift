import SwiftUI

/// The one time-range control (home net worth, Accounts chart, stock detail).
/// Neutral selected state (no accent fill — the range is a setting, not a call to action),
/// 44pt-tall hit targets, a selection tick, and spoken labels ("1 month", not "1M").
struct RangePicker: View {
    let options: [String]
    @Binding var selection: String
    /// Spread options across the full width (stock detail) or hug their content (inline rows).
    var fillsWidth: Bool = true
    var onChange: ((String) -> Void)? = nil

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: fillsWidth ? 0 : 2) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    guard !selected else { return }
                    withAnimation(Motion.tap) { selection = option }
                    onChange?(option)
                } label: {
                    Text(option)
                        .font(.subheadline.weight(selected ? .semibold : .regular))
                        .foregroundColor(selected ? AppTheme.primaryText : AppTheme.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background {
                            if selected {
                                LitPill()
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                        .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 44)
                        .frame(minWidth: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.spoken(option))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection) { _, _ in Haptic.isEnabled }
    }

    static func spoken(_ option: String) -> String {
        switch option {
        case "1D": return L("1 day")
        case "5D": return L("5 days")
        case "1M": return L("1 month")
        case "6M": return L("6 months")
        case "YTD": return L("Year to date")
        case "1Y": return L("1 year")
        case "ALL": return L("All time")
        default: return option
        }
    }
}
