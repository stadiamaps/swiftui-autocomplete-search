import OSLog

extension Logger {
    private static var subsystem = "com.stadiamaps.autocomplete-search-swiftui"

    /// Logging of API related events.
    static let api = Logger(subsystem: subsystem, category: "api")
}
