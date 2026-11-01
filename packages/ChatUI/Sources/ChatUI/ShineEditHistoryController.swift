import Cocoa
import TGUIKit
import SwiftSignalKit
import TelegramCore
import Postbox
import Localization
import TelegramContext
import TelegramTheme
import TelegramUtils
import InputDataUI

private struct State : Equatable {
    let entries: [ShineEditHistoryEntry]
    let current: String
}

private func entries(_ state: State) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []

    var sectionId:Int32 = 0
    var index: Int32 = 0

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    for entry in state.entries.reversed() {
        let header = entry.date > 0 ? stringForFullDate(timestamp: entry.date) : shineLocalized("Original", "Оригинал")
        entries.append(.desc(sectionId: sectionId, index: index, text: .plain(header), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
        index += 1
        entries.append(.desc(sectionId: sectionId, index: index, text: .plain(entry.text), data: .init(color: theme.colors.text, viewType: .singleItem)))
        index += 1
        entries.append(.sectionId(sectionId, type: .normal))
        sectionId += 1
    }

    return entries
}

func ShineEditHistoryModalController(context: any AccountContextProtocol, message: Message) -> InputDataModalController {
    let state = State(entries: message.shineEditHistory?.entries ?? [], current: message.text)

    let signal: Signal<InputDataSignalValue, NoError> = .single(InputDataSignalValue(entries: entries(state))) |> deliverOnPrepareQueue

    let controller = InputDataController(dataSignal: signal, title: shineLocalized("Edit History", "История изменений"))

    var close:(()->Void)? = nil

    let modalInteractions = ModalInteractions(acceptTitle: strings().modalDone, accept: {
        close?()
    }, singleButton: true)

    let modalController = InputDataModalController(controller, modalInteractions: modalInteractions)

    controller.leftModalHeader = ModalHeaderData(image: theme.icons.modalClose, handler: {
        close?()
    })

    close = { [weak modalController] in
        modalController?.modal?.close()
    }

    return modalController
}

func shineBotApiId(_ peerId: PeerId) -> String {
    let id = peerId.id._internalGetInt64Value()
    switch peerId.namespace {
    case Namespaces.Peer.CloudChannel:
        return "-100\(id)"
    case Namespaces.Peer.CloudGroup:
        return "-\(id)"
    default:
        return "\(id)"
    }
}

let shineSecondsDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none
    formatter.timeZone = NSTimeZone.local
    return formatter
}()
