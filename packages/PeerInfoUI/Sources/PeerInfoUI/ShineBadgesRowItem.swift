import Cocoa
import TGUIKit
import TelegramTheme
import GeneralRows
import Localization

final class ShineBadgesRowItem : GeneralRowItem {
    struct Chip {
        let badge: ShineBadge
        let text: TextViewLayout
        var frame: NSRect
    }

    let labelLayout: TextViewLayout
    private(set) var chips: [Chip]

    static let iconSize: CGFloat = 22
    static let chipHeight: CGFloat = 28
    static let spacing: CGFloat = 8

    init(_ initialSize: NSSize, stableId: AnyHashable, badges: [ShineBadge], viewType: GeneralViewType) {
        self.labelLayout = TextViewLayout(.initialize(string: shineLocalized("ShineGram badges", "Значки ShineGram"), color: theme.colors.accent, font: .normal(.text)), maximumNumberOfLines: 1)
        self.chips = badges.map { badge in
            Chip(badge: badge, text: TextViewLayout(.initialize(string: badge.name, color: theme.colors.text, font: .normal(.text)), maximumNumberOfLines: 1, truncationType: .end), frame: .zero)
        }
        super.init(initialSize, height: 60, stableId: stableId, viewType: viewType)
    }

    override func makeSize(_ width: CGFloat, oldWidth: CGFloat = 0) -> Bool {
        _ = super.makeSize(width, oldWidth: oldWidth)
        let available = blockWidth - viewType.innerInset.left - viewType.innerInset.right
        labelLayout.measure(width: available)
        var x: CGFloat = 0
        var y: CGFloat = 0
        for i in chips.indices {
            chips[i].text.measure(width: max(40, available - ShineBadgesRowItem.iconSize - 6))
            let chipWidth = ShineBadgesRowItem.iconSize + 6 + chips[i].text.layoutSize.width
            if x > 0 && x + chipWidth > available {
                x = 0
                y += ShineBadgesRowItem.chipHeight
            }
            chips[i].frame = NSMakeRect(x, y, chipWidth, ShineBadgesRowItem.chipHeight)
            x += chipWidth + ShineBadgesRowItem.spacing * 2
        }
        return true
    }

    var chipsTop: CGFloat {
        return viewType.innerInset.top + labelLayout.layoutSize.height + 6
    }

    override var height: CGFloat {
        let lines = (chips.map { $0.frame.maxY }.max() ?? ShineBadgesRowItem.chipHeight)
        return chipsTop + lines + viewType.innerInset.bottom
    }

    override func viewClass() -> AnyClass {
        return ShineBadgesRowView.self
    }

    override var accessibilityLabel: String? {
        return labelLayout.attributedString.string + ": " + chips.map { $0.badge.name }.joined(separator: ", ")
    }
}

private final class ShineBadgesRowView : GeneralContainableRowView {
    private let labelView = TextView()
    private var chipViews: [(ImageView, TextView)] = []

    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(labelView)
        labelView.userInteractionEnabled = false
        labelView.isSelectable = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateColors() {
        super.updateColors()
        labelView.backgroundColor = backdorColor
        for (_, text) in chipViews {
            text.backgroundColor = backdorColor
        }
    }

    override func set(item: TableRowItem, animated: Bool = false) {
        super.set(item: item, animated: animated)
        guard let item = item as? ShineBadgesRowItem else {
            return
        }
        labelView.update(item.labelLayout)
        while chipViews.count > item.chips.count {
            let (image, text) = chipViews.removeLast()
            image.removeFromSuperview()
            text.removeFromSuperview()
        }
        while chipViews.count < item.chips.count {
            let image = ImageView()
            let text = TextView()
            text.userInteractionEnabled = false
            text.isSelectable = false
            addSubview(image)
            addSubview(text)
            chipViews.append((image, text))
        }
        let scale = max(1, window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2)
        for (i, chip) in item.chips.enumerated() {
            let (image, text) = chipViews[i]
            image.image = shineBadgeImage(chip.badge, size: ShineBadgesRowItem.iconSize, scale: scale)
            image.setFrameSize(NSMakeSize(ShineBadgesRowItem.iconSize, ShineBadgesRowItem.iconSize))
            image.toolTip = chip.badge.name
            text.update(chip.text)
        }
        updateColors()
        needsLayout = true
    }

    override func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        super.updateLayout(size: size, transition: transition)
        guard let item = item as? ShineBadgesRowItem else {
            return
        }
        let left = item.viewType.innerInset.left
        transition.updateFrame(view: labelView, frame: NSMakeRect(left, item.viewType.innerInset.top, labelView.frame.width, labelView.frame.height))
        for (i, chip) in item.chips.enumerated() where i < chipViews.count {
            let (image, text) = chipViews[i]
            let origin = NSMakePoint(left + chip.frame.minX, item.chipsTop + chip.frame.minY)
            transition.updateFrame(view: image, frame: NSMakeRect(origin.x, origin.y + (ShineBadgesRowItem.chipHeight - ShineBadgesRowItem.iconSize) / 2, ShineBadgesRowItem.iconSize, ShineBadgesRowItem.iconSize))
            transition.updateFrame(view: text, frame: NSMakeRect(origin.x + ShineBadgesRowItem.iconSize + 6, origin.y + (ShineBadgesRowItem.chipHeight - text.frame.height) / 2, text.frame.width, text.frame.height))
        }
    }
}
