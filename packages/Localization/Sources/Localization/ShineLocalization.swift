import Foundation

private func isRussianCode(_ code: String) -> Bool {
    let code = code.lowercased()
    return code == "ru" || code.hasPrefix("ru-") || code.hasPrefix("ru_")
}

public func shineLocalized(_ english: String, _ russian: String) -> String {
    let language = appCurrentLanguage
    if isRussianCode(language.languageCode) || isRussianCode(language.primaryLanguage.languageCode) {
        return russian
    }
    return english
}
