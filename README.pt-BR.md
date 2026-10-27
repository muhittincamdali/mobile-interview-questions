<!-- i18n-source: README.md@04b5548078f8106d050b5817eaef73b730dabfa9 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg" alt="Mobile Interview Questions: Interview questions for iOS, Android, Flutter and React Native, with sourced answers and tested code."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml/badge.svg" alt="Status da CI"></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg" alt="Versão mais recente: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg" alt="Plataformas compatíveis: iOS 18+ · macOS 15+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg" alt="Versão da linguagem: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg" alt="Licença: MIT"></picture></a>
</p>

<p align="center">
<a href="#início-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-pt-BR-light.svg" alt="Começar"></picture></a>
<a href="https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-pt-BR-light.svg" alt="Documentação"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-pt-BR-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-pt-BR-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-pt-BR-light.svg" alt="Exemplos"></picture></a>
</p>

> Esta é uma tradução do README em inglês. Se houver diferença, vale a versão em inglês.

<!-- brand:end -->
Perguntas e respostas de entrevista para desenvolvedores mobile: iOS, Android, Flutter, React Native, design de sistemas mobile e rodadas comportamentais. O banco tem 142 perguntas, cada uma marcada como junior, mid ou senior, e toda resposta técnica leva à fonte primária em que se baseia: a documentação da Apple, do Android, do Flutter, do Dart, do Kotlin e do React Native, propostas do Swift Evolution, o MDN ou uma RFC. 51 respostas têm código que um teste executa no CI, de modo que as afirmações que elas fazem (um actor é reentrante, `Int(Double.nan)` causa um trap, um widget const não é reconstruído, `forEach` não espera) são verificadas em vez de apenas repetidas.

Você pode ler as perguntas aqui no GitHub, testar-se no terminal com o comando `interview` ou estudá-las no app InterviewDeck para iPhone, iPad e Mac.

## Destaques

- **Plataformas atuais** — o modo de linguagem Swift 6 com isolamento main-actor por padrão e `@concurrent`, o ciclo de vida baseado em scenes que os apps compilados com o SDK do iOS 27 precisam adotar, as mudanças do Android 16 para telas grandes e predictive back, os patterns e extension types do Dart 3 e a New Architecture do React Native.
- **Respostas que você pode conferir** — toda resposta técnica cita uma fonte primária, e o linter rejeita a que não cita.
- **Código testado** — as respostas em Swift rodam com Swift Testing no macOS e em um simulador de iPhone, as de Dart e Flutter com `flutter test` (incluindo testes de widget) e as de JavaScript com `node --test`. Cada teste leva o nome da pergunta que verifica.
- **Uma ferramenta de estudo** — `swift run interview quiz` sorteia perguntas por track e nível; com a mesma seed, o mesmo quiz se repete em qualquer máquina.
- **Um único formato, com lint** — as perguntas são Markdown simples com estrutura fixa, então os mesmos arquivos alimentam o GitHub, a linha de comando, o app e a biblioteca [InterviewBank](#usar-a-biblioteca).

### O que há no banco

| Track                                         | Tópicos                                                                                                               | Perguntas | Com código testado |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | --------: | -----------------: |
| [iOS](questions/ios)                          | A linguagem Swift, memória, concorrência, SwiftUI, UIKit e o ciclo de vida do app, dados e rede, testes e ferramentas |        58 |                 26 |
| [Android](questions/android)                  | Kotlin e corrotinas, o framework Android e o Jetpack                                                                  |        22 |                  — |
| [Flutter](questions/flutter)                  | A linguagem Dart, o framework Flutter                                                                                 |        22 |                 14 |
| [React Native](questions/react-native)        | JavaScript para React Native, React Native                                                                            |        22 |                 11 |
| [Design de sistemas](questions/system-design) | Sincronização offline, feeds, imagens, chat, push, OAuth, rollouts graduais, evolução de APIs, novas tentativas       |        10 |                  — |
| [Comportamental](questions/behavioral)        | STAR, incidentes, divergências, dívida técnica, mentoria                                                              |         8 |                  — |

Os trechos de Android não são compilados: o CI não tem uma toolchain de Kotlin para eles, então essas respostas se apoiam na documentação indicada. A lista completa dos arquivos de tópicos está em [questions/README.md](questions/README.md).

## Início rápido

**1. Obtenha as perguntas**

```sh
git clone https://github.com/muhittincamdali/mobile-interview-questions.git
cd mobile-interview-questions
```

Você precisa do Swift 6.2 ou posterior: Xcode 26 ou posterior em um Mac, ou uma [toolchain do Swift](https://www.swift.org/install/) no Linux. Para apenas ler os arquivos Markdown, não é preciso nada.

**2. Execute um quiz**

```sh
swift run interview quiz --track ios --level senior --count 3
```

Na primeira execução, a ferramenta é compilada. Em seguida, ela mostra três perguntas e a seed usada:

```console
$ swift run interview quiz --track ios --level senior --count 3 --seed 7
Quiz: 3 of 12 questions · seed 7

1. [IOS-021 · senior · Memory management] Is `autoreleasepool` still useful in Swift?
2. [IOS-029 · senior · Swift concurrency] Where does a `nonisolated async` function run, and what do `nonisolated(nonsending)` and `@concurrent` mean?
3. [IOS-047 · senior · UIKit and the app life cycle] How do you run work in the background on iOS?

Answers: interview show <ID>, or repeat with --seed 7 --answers
```

**3. Confira sua resposta**

```sh
swift run interview show IOS-026
```

Isso mostra a resposta, suas referências e o teste que verifica o código dela ([ConcurrencyTests.swift](Tests/AnswerTests/ConcurrencyTests.swift) para IOS-026). Adicione `--answers` a um quiz com a mesma seed para mostrar todas de uma vez.

## Comandos

| Comando                                         | O que faz                                                                         |
| ----------------------------------------------- | --------------------------------------------------------------------------------- |
| `interview list --track flutter --level mid`    | Lista perguntas; também aceita `--topic "Swift concurrency"` e `--search actor`   |
| `interview show RN-012`                         | Uma pergunta com a resposta, as referências e o teste                             |
| `interview quiz --count 10 --seed 42 --answers` | Um quiz repetível de 1 a 50 perguntas                                             |
| `interview stats`                               | Perguntas por track e nível                                                       |
| `interview lint`                                | Verifica os arquivos de perguntas; status de saída 1 em caso de qualquer problema |

Execute `swift run interview --help` para ver a lista completa. Entradas inválidas, como `--count 0`, `--count 1e3` ou um track desconhecido, são reportadas com status de saída 2 em vez de travar o programa.

## Exemplo: uma resposta verificada

Cada pergunta é uma seção Markdown com um ID, um nível, a resposta e suas fontes. Este é o início de IOS-012 em [questions/ios/swift-language.md](questions/ios/swift-language.md):

```markdown
## IOS-012: How do you convert a `Double` to an `Int` without crashing?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

`Int(someDouble)` truncates toward zero, and it **traps** (crashes) when the value is NaN,
infinite or outside `Int`'s range. ...
```

O teste vinculado executa todas as conversões da resposta e falha se alguma se comportar de outra forma:

```swift
@Test("IOS-012: Int(exactly:) returns nil where Int(_:) would trap")
func safeNumericConversion() throws {
    #expect(Int(exactly: 42.0) == 42)
    #expect(Int(exactly: 3.5) == nil)
    #expect(Int(exactly: Double.nan) == nil)
    let huge = try #require(Double("1e300"), "read at run time, like a value from JSON")
    #expect(Int(exactly: huge) == nil)
    #expect(Int(3.9) == 3, "Int(_:) truncates toward zero")
    // ...
}
```

Escrever esses testes corrigiu rascunhos antes da publicação: por exemplo, `Int(1e300)` com um literal simplesmente não compila, então a resposta agora mostra o trap com um valor conhecido apenas em tempo de execução.

## O app de estudo

O [InterviewDeck](Examples) é um app SwiftUI para iPhone, iPad e Mac construído sobre os mesmos arquivos: navegue e pesquise no banco, leia as respostas com código, tabelas e referências e faça quizzes por track e nível.

<p align="center">
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-browse-dark.png"><img src="docs/images/deck-browse-light.png" alt="Lista de perguntas do InterviewDeck: 142 perguntas em seis tracks" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-question-dark.png"><img src="docs/images/deck-question-light.png" alt="InterviewDeck mostrando a pergunta IOS-026 sobre a reentrância de actors, com o exemplo de código" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-quiz-dark.png"><img src="docs/images/deck-quiz-light.png" alt="Card de quiz do InterviewDeck para uma pergunta de iOS de nível senior, com a resposta exibida" width="260"></picture>
</p>

Abra `Examples/InterviewDeck/InterviewDeck.xcodeproj` no Xcode 26 ou posterior, escolha o scheme **InterviewDeck** e um simulador de iPhone ou **My Mac** e pressione **Run**. As capturas de tela são feitas a partir do app em um simulador de iOS 27 por [`scripts/capture-screens.sh`](scripts/capture-screens.sh).

## Usar a biblioteca

A biblioteca `InterviewBank` lê, verifica com lint, filtra e transforma em quiz os arquivos de perguntas a partir do seu próprio código Swift. Adicione-a com o Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/mobile-interview-questions.git", from: "2.0.0")
],
targets: [
    .target(name: "MyStudyTool", dependencies: [
        .product(name: "InterviewBank", package: "mobile-interview-questions")
    ])
]
```

```swift
import Foundation
import InterviewBank

let bank = try QuestionBank.load(from: URL(fileURLWithPath: "questions"))
let pool = bank.filter(QuestionFilter(track: .flutter, level: .mid))
for question in Quiz.pick(5, from: pool, seed: 2026) {
    print(question.id, question.title)
}
```

A leitura tem limites (1 MiB por arquivo, 256 arquivos, 500 perguntas e 100 problemas relatados por arquivo), e todo problema de formato volta como um `Diagnostic` com arquivo e linha, em vez de uma exceção.

## Documentação

A [documentação do InterviewBank](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/) cobre a API e três artigos:

- [Getting Started](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/gettingstarted) — os comandos e como adicionar a biblioteca
- [Writing Questions](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/writingquestions) — o formato dos arquivos, as regras de lint e como verificar uma resposta
- [Building a Study App](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/buildingastudyapp) — incluir as perguntas no app e exibir as respostas

## Requisitos

| Uso                                | Requer                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------- |
| Ler as perguntas                   | Um navegador ou qualquer visualizador de Markdown                               |
| Comando `interview`                | Swift 6.2 ou posterior (Xcode 26+ no macOS, ou uma toolchain do Swift no Linux) |
| Biblioteca `InterviewBank`         | Swift 6.2+, iOS 18+ ou macOS 15+                                                |
| App InterviewDeck                  | Xcode 26+, iOS 18+ ou macOS 15+                                                 |
| Testes das respostas em Flutter    | Flutter 3.41 ou posterior (`cd answers/flutter && flutter test`)                |
| Testes das respostas em JavaScript | Node.js 22 ou posterior (`cd answers/react-native && npm test`)                 |

## Como contribuir

Correções e novas perguntas são bem-vindas. Leia o [guia de contribuição](CONTRIBUTING.md) para conhecer o formato, as regras de lint e como adicionar um teste a uma resposta, e o [código de conduta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir um pull request. Relate problemas de segurança de forma privada, como descrito na [política de segurança](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Licença

Publicado sob a licença MIT. Veja [LICENSE](LICENSE).
