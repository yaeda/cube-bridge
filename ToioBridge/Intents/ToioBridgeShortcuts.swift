import AppIntents

struct ToioBridgeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MoveCubeIntent(),
            phrases: [
                "Move \(.applicationName) cube",
                "Move toio cube with \(.applicationName)"
            ],
            shortTitle: "Move toio Cube",
            systemImageName: "arrow.up.circle"
        )

        AppShortcut(
            intent: StopCubeIntent(),
            phrases: [
                "Stop \(.applicationName) cube",
                "Stop toio cube with \(.applicationName)"
            ],
            shortTitle: "Stop toio Cube",
            systemImageName: "stop.circle"
        )

        AppShortcut(
            intent: SetLampIntent(),
            phrases: [
                "Set \(.applicationName) lamp",
                "Set toio lamp with \(.applicationName)"
            ],
            shortTitle: "Set toio Lamp",
            systemImageName: "lightbulb"
        )

        AppShortcut(
            intent: TurnOffLampIntent(),
            phrases: [
                "Turn off \(.applicationName) lamp",
                "Turn off toio lamp with \(.applicationName)"
            ],
            shortTitle: "Turn Off toio Lamp",
            systemImageName: "lightbulb.slash"
        )
    }
}
