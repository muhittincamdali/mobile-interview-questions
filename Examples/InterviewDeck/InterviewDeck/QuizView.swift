import InterviewBank
import SwiftUI

/// Pick a track, a level and a number of questions, then go through them one card at a time.
struct QuizView: View {
    @Environment(DeckModel.self) private var model
    @State private var track: Track?
    @State private var level: Level?
    @State private var count = 5
    let startImmediately: Bool

    var body: some View {
        NavigationStack {
            Group {
                if model.quiz != nil {
                    QuizCard()
                } else {
                    setup
                }
            }
            .navigationTitle("Quiz")
        }
        .task {
            // The screenshot script opens a fixed quiz so the image is reproducible.
            if startImmediately && model.quiz == nil {
                model.startQuiz(track: .ios, level: .senior, count: 5, seed: 2026)
                model.quiz?.reveal()
            }
        }
    }

    private var setup: some View {
        Form {
            Picker("Track", selection: $track) {
                Text("All tracks").tag(Track?.none)
                ForEach(model.tracks, id: \.self) { track in
                    Text(track.displayName).tag(Track?.some(track))
                }
            }
            Picker("Level", selection: $level) {
                Text("Any level").tag(Level?.none)
                ForEach(Level.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(Level?.some(level))
                }
            }
            Stepper("\(count) questions", value: $count, in: 1...20)
            Button("Start quiz") {
                model.startQuiz(track: track, level: level, count: count, seed: UInt64.random(in: 0...UInt64.max))
            }
            .disabled(model.bank.filter(QuestionFilter(track: track, level: level)).isEmpty)
        }
    }
}

struct QuizCard: View {
    @Environment(DeckModel.self) private var model

    var body: some View {
        if let session = model.quiz, let question = session.current {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Question \(session.index + 1) of \(session.questions.count) · from \(session.poolSize) · seed \(String(session.seed))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    QuestionHeader(question: question)
                    if session.isRevealed {
                        AnswerView(markdown: question.answer)
                        ReferencesView(question: question)
                    } else {
                        Button {
                            model.quiz?.reveal()
                        } label: {
                            Label("Show answer", systemImage: "eye")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
                .frame(maxWidth: 760, alignment: .leading)
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Previous", systemImage: "chevron.left") { model.quiz?.move(by: -1) }
                        .disabled(session.index == 0)
                    Button("Next", systemImage: "chevron.right") { model.quiz?.move(by: 1) }
                        .disabled(session.index == session.questions.count - 1)
                    Button("End quiz", systemImage: "xmark") { model.quiz = nil }
                }
            }
        } else {
            ContentUnavailableView("No questions match", systemImage: "rectangle.on.rectangle.slash")
        }
    }
}
