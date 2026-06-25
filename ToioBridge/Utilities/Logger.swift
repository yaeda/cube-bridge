import OSLog

enum AppLogger {
    static let bluetooth = Logger(subsystem: "io.github.yaeda.ToioBridge", category: "Bluetooth")
    static let intents = Logger(subsystem: "io.github.yaeda.ToioBridge", category: "Intents")
}
