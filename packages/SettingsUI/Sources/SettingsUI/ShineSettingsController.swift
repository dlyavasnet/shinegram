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
    let selectIcon: (ShineAppIconVariant) -> Void
    let openChannel: () -> Void
    init(context: any AccountContextProtocol, toggle: @escaping (ShineSettings.Key) -> Void, toggleGhostMode: @escaping () -> Void, selectIcon: @escaping (ShineAppIconVariant) -> Void, openChannel: @escaping () -> Void) {
        self.context = context
        self.toggle = toggle
        self.toggleGhostMode = toggleGhostMode
        self.selectIcon = selectIcon
        self.openChannel = openChannel
    }
}

private struct State : Equatable {
    var values: [ShineSettings.Key: Bool]
    var iconId: String

    static func load() -> State {
        var values: [ShineSettings.Key: Bool] = [:]
        for key in ShineSettings.Key.allCases {
            values[key] = ShineSettings.value(key)
        }
        return State(values: values, iconId: ShineAppIcons.selected.id)
    }

    func value(_ key: ShineSettings.Key) -> Bool {
        return values[key] ?? false
    }

    var ghostMode: Bool {
        return ShineSettings.ghostKeys.allSatisfy { value($0) }
    }
}

private let _id_ghost_mode = InputDataIdentifier("_id_ghost_mode")
private let _id_channel = InputDataIdentifier("_id_channel")
private func _id_key(_ key: ShineSettings.Key) -> InputDataIdentifier {
    return InputDataIdentifier("_id_\(key.rawValue)")
}
private func _id_icon(_ variant: ShineAppIconVariant) -> InputDataIdentifier {
    return InputDataIdentifier("_id_icon_\(variant.id)")
}

private var iconPreviews: [String: CGImage] = [:]
private let iconPreviewsLock = NSLock()

private func iconPreview(_ variant: ShineAppIconVariant) -> CGImage {
    iconPreviewsLock.lock()
    defer { iconPreviewsLock.unlock() }
    if let image = iconPreviews[variant.id] {
        return image
    }
    let image = shineSettingsIcon(variant, reference: theme.icons.settingsGeneral)
    iconPreviews[variant.id] = image
    return image
}

private func title(_ key: ShineSettings.Key) -> String {
    switch key {
    case .ghostHideReadReceipts:
        return shineLocalized("Don't Send Read Receipts", "Не отправлять отметку о прочтении")
    case .ghostHideOnline:
        return shineLocalized("Don't Send Online Status", "Не отправлять статус «в сети»")
    case .ghostHideTyping:
        return shineLocalized("Don't Send Typing Status", "Не отправлять статус «печатает»")
    case .ghostHideStoryViews:
        return shineLocalized("Don't Mark Stories as Viewed", "Не отмечать истории просмотренными")
    case .ghostHideMediaListened:
        return shineLocalized("Don't Mark Voice and Video Messages as Played", "Не отмечать голосовые и кружки прослушанными")
    case .ghostSendAsScheduled:
        return shineLocalized("Keep Chats Unread When Sending", "Не читать чат при отправке")
    case .saveDeletedMessages:
        return shineLocalized("Save Deleted Messages", "Сохранять удалённые сообщения")
    case .saveEditHistory:
        return shineLocalized("Save Edit History", "Сохранять историю изменений")
    case .hideSponsoredMessages:
        return shineLocalized("Hide Sponsored Messages", "Скрывать рекламу в каналах")
    case .streamerMode:
        return shineLocalized("Streamer Mode", "Режим стримера")
    case .hideStories:
        return shineLocalized("Hide Stories", "Скрыть истории")
    case .showMessageSeconds:
        return shineLocalized("Show Seconds in Message Time", "Показывать секунды у сообщений")
    case .showIds:
        return shineLocalized("Show IDs", "Показывать ID")
    case .hidePhone:
        return shineLocalized("Blur Phone Numbers in Profiles", "Размывать номера в профилях")
    case .hideUsername:
        return shineLocalized("Blur Usernames in Profiles", "Размывать юзернеймы в профилях")
    }
}

private func header(_ text: String, sectionId: Int32, index: inout Int32) -> InputDataEntry {
    defer { index += 1 }
    return .desc(sectionId: sectionId, index: index, text: .plain(text), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem))
}

private func footer(_ text: String, sectionId: Int32, index: inout Int32) -> InputDataEntry {
    defer { index += 1 }
    return .desc(sectionId: sectionId, index: index, text: .plain(text), data: .init(color: theme.colors.listGrayText, viewType: .textBottomItem))
}

private func switches(_ keys: [ShineSettings.Key], state: State, arguments: Arguments, sectionId: Int32, index: inout Int32) -> [InputDataEntry] {
    var entries: [InputDataEntry] = []
    for (i, key) in keys.enumerated() {
        entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_key(key), data: .init(name: title(key), color: theme.colors.text, type: .switchable(state.value(key)), viewType: bestGeneralViewType(keys, for: i), action: {
            arguments.toggle(key)
        })))
        index += 1
    }
    return entries
}

private func entries(_ state: State, arguments: Arguments) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []

    var sectionId:Int32 = 0
    var index: Int32 = 0

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(header(shineLocalized("GHOST MODE", "РЕЖИМ ПРИЗРАКА"), sectionId: sectionId, index: &index))
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_ghost_mode, data: .init(name: shineLocalized("Ghost Mode", "Режим призрака"), color: theme.colors.text, type: .switchable(state.ghostMode), viewType: .singleItem, action: arguments.toggleGhostMode)))
    index += 1
    entries.append(footer(shineLocalized("Also available from the ghost button at the top of the chat list.", "Также включается кнопкой-призраком вверху списка чатов."), sectionId: sectionId, index: &index))

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(contentsOf: switches(ShineSettings.ghostKeys, state: state, arguments: arguments, sectionId: sectionId, index: &index))
    entries.append(footer(shineLocalized("Ghost mode stops the app from telling others that you are online, typing, have read their messages or watched their stories. With \"Keep Chats Unread When Sending\", your messages are sent as scheduled with a \(ShineSettings.ghostScheduleDelay)-second delay, so the server does not mark the chat as read and does not show you online.", "Режим призрака не даёт другим узнать, что вы в сети, печатаете, прочитали их сообщения или посмотрели истории. С «Не читать чат при отправке» ваши сообщения уходят как отложенные с задержкой \(ShineSettings.ghostScheduleDelay) секунд, поэтому сервер не помечает чат прочитанным и не показывает вас в сети."), sectionId: sectionId, index: &index))

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(header(shineLocalized("MESSAGES", "СООБЩЕНИЯ"), sectionId: sectionId, index: &index))
    entries.append(contentsOf: switches([.saveDeletedMessages, .saveEditHistory, .hideSponsoredMessages], state: state, arguments: arguments, sectionId: sectionId, index: &index))
    entries.append(footer(shineLocalized("Deleted messages stay in the chat with a \"deleted\" mark. Previous versions of edited messages are available from the message context menu. Both only work while the app is running and only on this device.", "Удалённые сообщения остаются в чате с пометкой «удалено». Прошлые версии изменённых сообщений открываются из контекстного меню сообщения. Работает, только пока приложение запущено, и только на этом устройстве."), sectionId: sectionId, index: &index))

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(header(shineLocalized("INTERFACE", "ИНТЕРФЕЙС"), sectionId: sectionId, index: &index))
    entries.append(contentsOf: switches([.streamerMode, .hidePhone, .hideUsername, .hideStories, .showMessageSeconds, .showIds], state: state, arguments: arguments, sectionId: sectionId, index: &index))
    entries.append(footer(shineLocalized("Streamer mode hides ShineGram windows from screenshots, screen recording and screen sharing, turns off notifications and hides everyone's phone numbers. The eye button next to a phone number or username in a profile blurs it; the choice is remembered.", "Режим стримера скрывает окна ShineGram со скриншотов, записи и демонстрации экрана, отключает уведомления и скрывает номера телефонов у всех. Кнопка с глазом рядом с номером или юзернеймом в профиле размывает его, выбор запоминается."), sectionId: sectionId, index: &index))

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(header(shineLocalized("APP ICON", "ИКОНКА ПРИЛОЖЕНИЯ"), sectionId: sectionId, index: &index))
    let variants = ShineAppIconVariant.all
    for (i, variant) in variants.enumerated() {
        entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_icon(variant), data: .init(name: variant.name, color: theme.colors.text, icon: iconPreview(variant), type: .selectable(state.iconId == variant.id), viewType: bestGeneralViewType(variants, for: i), action: {
            arguments.selectIcon(variant)
        })))
        index += 1
    }

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: _id_channel, data: .init(name: shineLocalized("Creator's Channel", "Канал создателя"), color: theme.colors.accent, icon: shineChannelIcon(reference: theme.icons.settingsGeneral), type: .context("@dlyavasnet"), viewType: .singleItem, action: arguments.openChannel)))
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

    let observer = NotificationCenter.default.addObserver(forName: ShineSettings.didChangeNotification, object: nil, queue: .main, using: { _ in
        updateState { _ in State.load() }
    })

    let arguments = Arguments(context: context, toggle: { key in
        ShineSettings.set(key, !ShineSettings.value(key))
        updateState { _ in State.load() }
    }, toggleGhostMode: {
        ShineSettings.setGhostMode(!ShineSettings.isGhostModeEnabled)
        updateState { _ in State.load() }
    }, selectIcon: { variant in
        ShineAppIcons.select(variant)
        updateState { _ in State.load() }
    }, openChannel: {
        ShineHooks.openLink?(ShineHooks.creatorChannelUrl, context)
    })

    let signal = statePromise.get() |> deliverOnPrepareQueue |> map { state in
        return InputDataSignalValue(entries: entries(state, arguments: arguments))
    }

    let controller = InputDataController(dataSignal: signal, title: "ShineGram")

    controller.onDeinit = {
        actionsDisposable.dispose()
        NotificationCenter.default.removeObserver(observer)
    }

    return controller
}
