import Foundation

extension Locale {
    static var app: Locale {
        guard let language = Bundle.main.preferredLocalizations.first else {
            return .current
        }
        var components = Locale.Components(locale: .current)
        components.languageComponents.languageCode = Locale.Language(identifier: language).languageCode
        return Locale(components: components)
    }
}
