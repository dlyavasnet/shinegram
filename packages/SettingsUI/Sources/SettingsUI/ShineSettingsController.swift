import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Localization
import TelegramContext
import TelegramTheme
import TelegramUtils
import InputDataUI
import GeneralRows

private final class Arguments {
    let context: any AccountContextProtocol
    let toggle: (ShineSettings.Key) -> Void
    let toggleGhostMode: () -> Void
    init(context: any AccountContextProtocol, toggle: @escaping (ShineSettings.Key) -> Void, toggleGhostMode: @escaping () -> Void) {
        self.context = context
        self.toggle = toggle
        self.toggleGhostMode = toggleGhostMode
    }
}

private struct State : Equatable {
    var values: [ShineSettings.Key: Bool]

    static func load() -> State {
        var values: [ShineSettings.Key: Bool] = [:]
        for key in ShineSettings.Key.allCases {
            values[key] = ShineSettings.value(key)
        }
        return State(values: values)
    }

    func value(_ key: ShineSettings.Key) -> Bool {
        return values[key] ?? false
    }

    var ghostMode: Bool {
        return ShineSettings.ghostKeys.allSatisfy { value($0) }
    }
}

private let _id_ghost_mode = InputDataIdentifier("_id_ghost_mode")
private func _id_key(_ key: ShineSettings.Key) -> InputDataIdentifier {
    return InputDataIdentifier("_id_\(key.rawValue)")
}

private func title(_ key: ShineSettings.Key) -> String {
    switch key {
    case .ghostHideReadReceipts:
        return "Don't Send Read Receipts" //TODOLANG
    case .ghostHideOnline:
        return "Don't Send Online Status" //TODOLANG
    case .ghostHideTyping:
        return "Don't Send Typing Status" //TODOLANG
    case .ghostHideStoryViews:
        return "Don't Mark Stories as Viewed" //TODOLANG
    case .ghostHideMediaListened:
        return "Don't Mark Voice and Video Messages as Played" //TODOLANG
    case .saveDeletedMessages:
        return "Save Deleted Messages" //TODOLANG
    case .saveEditHistory:
        return "Save Edit History" //TODOLANG
    case .hideSponsoredMessages:
        return "Hide Sponsored Messages" //TODOLANG
    }
}

private func entries(_ state: State, arguments: Arguments) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []

    var sectionId:Int32 = 0
    var index: Int32 = 0

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain("GHOST MODE"), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem))) //TODOLANG
    index += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_ghost_mode, data: .init(name: "Ghost Mode", color: theme.colors.text, type: .switchable(state.ghostMode), viewType: .singleItem, action: arguments.toggleGhostMode))) //TODOLANG
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    let ghostKeys = ShineSettings.ghostKeys
    for (i, key) in ghostKeys.enumerated() {
        entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_key(key), data: .init(name: title(key), color: theme.colors.text, type: .switchable(state.value(key)), viewType: bestGeneralViewType(ghostKeys, for: i), action: {
            arguments.toggle(key)
        })))
        index += 1
    }

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain("Ghost mode stops the app from telling others that you are online, typing, have read their messages or watched their stories. Sending a message may still reveal that you are online."), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem))) //TODOLANG
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain("MESSAGES"), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem))) //TODOLANG
    index += 1

    let messageKeys: [ShineSettings.Key] = [.saveDeletedMessages, .saveEditHistory, .hideSponsoredMessages]
    for (i, key) in messageKeys.enumerated() {
        entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_key(key), data: .init(name: title(key), color: theme.colors.text, type: .switchable(state.value(key)), viewType: bestGeneralViewType(messageKeys, for: i), action: {
            arguments.toggle(key)
        })))
        index += 1
    }

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain("Deleted messages stay in the chat with a \"deleted\" mark. Previous versions of edited messages are available from the message context menu. Both only work while the app is running and only on this device."), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem))) //TODOLANG
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    return entries
}

public func ShineSettingsController(context: any AccountContextProtocol) -> InputDataController {

    let actionsDisposable = DisposableSet()

    let initialState = State.load()

    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((State) -> State) -> Void = { f in
        statePromise.set(stateValue.modify (f))
    }

    let arguments = Arguments(context: context, toggle: { key in
        ShineSettings.set(key, !ShineSettings.value(key))
        updateState { _ in State.load() }
    }, toggleGhostMode: {
        ShineSettings.setGhostMode(!ShineSettings.isGhostModeEnabled)
        updateState { _ in State.load() }
    })

    let signal = statePromise.get() |> deliverOnPrepareQueue |> map { state in
        return InputDataSignalValue(entries: entries(state, arguments: arguments))
    }

    let controller = InputDataController(dataSignal: signal, title: "ShineGram") //TODOLANG

    controller.onDeinit = {
        actionsDisposable.dispose()
    }

    return controller
}
