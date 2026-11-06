import Foundation

extension Locale {
    static var app: Locale {
        guard let language = Bundle.main.preferredLocalizations.first else {
            return .current
        }
        var components = Locale.Components(locale: .current)
        components.languageComponents = Locale.Language.Components(identifier: language)
        return Locale(components: components)
    }
}
