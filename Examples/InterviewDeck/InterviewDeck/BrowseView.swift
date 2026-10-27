import InterviewBank
import SwiftUI

enum BrowseRoute: Hashable {
    case track(Track)
    case question(String)
}

/// Tracks, then topics and questions, with search across the whole bank.
struct BrowseView: View {
    @Environment(DeckModel.self) private var model
    @State private var path: [BrowseRoute]
    @State private var searchText = ""

    init(openQuestion: String?) {
        _path = State(initialValue: openQuestion.map { [.question($0)] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if let error = model.loadError {
                    Section("Problems in the question files") {
                        Text(error).font(.footnote.monospaced()).foregroundStyle(.red)
                    }
                }
                if searchText.isEmpty {
                    Section {
                        ForEach(model.tracks, id: \.self) { track in
                            NavigationLink(value: BrowseRoute.track(track)) {
                                LabeledContent(track.displayName, value: "\(model.count(in: track))")
                            }
                        }
                    } header: {
                        Text("\(model.bank.questions.count) questions")
                    } footer: {
                        Text("\(model.bank.questions.count { $0.verifiedBy != nil }) answers have code that a test runs. Search covers questions and answers.")
                    }
                } else {
                    let results = model.search(searchText)
                    Section("\(results.count) results") {
                        ForEach(results) { question in
                            NavigationLink(value: BrowseRoute.question(question.id)) {
                                QuestionRow(question: question, showsTrack: true)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Interview Deck")
            .searchable(text: $searchText, prompt: "Search questions and answers")
            .navigationDestination(for: BrowseRoute.self) { route in
                switch route {
                case .track(let track):
                    TrackView(track: track)
                case .question(let id):
                    if let question = model.question(id: id) {
                        QuestionView(question: question)
                    } else {
                        ContentUnavailableView("No question \(id)", systemImage: "questionmark.folder")
                    }
                }
            }
        }
    }
}

struct TrackView: View {
    @Environment(DeckModel.self) private var model
    let track: Track

    var body: some View {
        List {
            ForEach(model.sections(in: track), id: \.topic) { section in
                Section(section.topic) {
                    ForEach(section.questions) { question in
                        NavigationLink(value: BrowseRoute.question(question.id)) {
                            QuestionRow(question: question, showsTrack: false)
                        }
                    }
                }
            }
        }
        .navigationTitle(track.displayName)
    }
}

struct QuestionRow: View {
    let question: Question
    let showsTrack: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question.title)
            HStack(spacing: 6) {
                Text(question.id).monospaced()
                LevelBadge(level: question.level)
                if showsTrack { Text(question.track.displayName) }
                if question.verifiedBy != nil {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.deckBlue)
                        .accessibilityLabel("Code checked by a test")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct LevelBadge: View {
    let level: Level

    var body: some View {
        Text(level.rawValue)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Color.deckBlue.opacity(0.12 + 0.12 * Double(Level.allCases.firstIndex(of: level) ?? 0)), in: Capsule())
            .foregroundStyle(Color.deckBlue)
    }
}
