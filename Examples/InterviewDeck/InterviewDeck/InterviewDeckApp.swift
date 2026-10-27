import InterviewBank
import SwiftUI

@main
struct InterviewDeckApp: App {
    @State private var model = DeckModel.bundled()

    var body: some Scene {
        WindowGroup {
            RootView(initialScreen: LaunchScreen(arguments: UserDefaults.standard))
                .environment(model)
                .tint(.deckBlue)
        }
    }
}

/// Which screen to open at launch. The screenshot script passes `-screen quiz` or
/// `-screen question:IOS-026`; a normal launch opens the question list.
enum LaunchScreen: Equatable {
    case browse
    case question(String)
    case quiz

    init(arguments: UserDefaults) {
        let value = arguments.string(forKey: "screen") ?? ""
        if value == "quiz" {
            self = .quiz
        } else if value.hasPrefix("question:") {
            self = .question(String(value.dropFirst("question:".count)))
        } else {
            self = .browse
        }
    }
}

extension Color {
    /// The brand blue (#0071E3) used across the repository's graphics.
    static let deckBlue = Color(red: 0, green: 0x71 / 255, blue: 0xE3 / 255)
}

struct RootView: View {
    let initialScreen: LaunchScreen
    @State private var tab: Tab

    enum Tab: Hashable { case browse, quiz }

    init(initialScreen: LaunchScreen) {
        self.initialScreen = initialScreen
        _tab = State(initialValue: initialScreen == .quiz ? .quiz : .browse)
    }

    var body: some View {
        TabView(selection: $tab) {
            SwiftUI.Tab("Questions", systemImage: "list.bullet.rectangle", value: Tab.browse) {
                BrowseView(openQuestion: initialScreen.questionID)
            }
            SwiftUI.Tab("Quiz", systemImage: "rectangle.on.rectangle.angled", value: Tab.quiz) {
                QuizView(startImmediately: initialScreen == .quiz)
            }
        }
    }
}

private extension LaunchScreen {
    var questionID: String? {
        if case .question(let id) = self { return id }
        return nil
    }
}
