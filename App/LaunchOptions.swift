import Foundation

struct LaunchOptions {
    let now: Date

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        now = Self.fixedNow(in: arguments) ?? .now
    }

    private static func fixedNow(in arguments: [String]) -> Date? {
        #if DEBUG
            guard let flagIndex = arguments.firstIndex(of: "--now"), arguments.indices.contains(flagIndex + 1) else {
                return nil
            }
            return try? Date(arguments[flagIndex + 1], strategy: .iso8601)
        #else
            return nil
        #endif
    }
}
