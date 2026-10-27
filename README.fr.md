<!-- i18n-source: README.md@1616d72d635be23227644c65d518040fd9e862bc status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg" alt="Mobile Interview Questions: Interview questions for iOS, Android, Flutter and React Native, with sourced answers and tested code."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml/badge.svg" alt="État de la CI"></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg" alt="Dernière version: v2.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg" alt="Plateformes prises en charge: iOS 18+ · macOS 15+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg" alt="Version du langage: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg" alt="Licence: MIT"></picture></a>
</p>

<p align="center">
<a href="#démarrage-rapide"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-fr-light.svg" alt="Commencer"></picture></a>
<a href="https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-fr-light.svg" alt="Documentation"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-fr-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-fr-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-fr-light.svg" alt="Exemples"></picture></a>
</p>

> Ceci est une traduction du README anglais. En cas de différence, la version anglaise fait foi.

<!-- brand:end -->
Questions et réponses d’entretien pour les développeurs mobiles : iOS, Android, Flutter, React Native, conception de systèmes mobiles et entretiens comportementaux. La banque compte 142 questions, chacune étiquetée junior, mid ou senior, et chaque réponse technique renvoie à la source primaire sur laquelle elle s’appuie : la documentation d’Apple, d’Android, de Flutter, de Dart, de Kotlin et de React Native, les propositions Swift Evolution, MDN ou un RFC. 51 réponses comportent du code qu’un test exécute en CI, si bien que les affirmations qu’elles avancent (un actor est réentrant, `Int(Double.nan)` provoque un trap, un widget const n’est pas reconstruit, `forEach` n’attend pas) sont vérifiées plutôt que répétées.

Vous pouvez lire les questions ici sur GitHub, vous entraîner dans le terminal avec la commande `interview`, ou les étudier dans l’application InterviewDeck pour iPhone, iPad et Mac.

## Points forts

- **Plateformes actuelles** — le mode de langage Swift 6 avec isolation main-actor par défaut et `@concurrent`, le cycle de vie basé sur les scenes que doivent adopter les apps compilées avec le SDK iOS 27, les changements d’Android 16 pour les grands écrans et le predictive back, les patterns et les extension types de Dart 3, ainsi que la New Architecture de React Native.
- **Des réponses vérifiables** — chaque réponse technique cite une source primaire, et le linter rejette toute réponse qui n’en cite pas.
- **Du code testé** — les réponses Swift s’exécutent avec Swift Testing sur macOS et dans un simulateur d’iPhone, les réponses Dart et Flutter avec `flutter test` (y compris les tests de widgets) et les réponses JavaScript avec `node --test`. Chaque test porte le nom de la question qu’il vérifie.
- **Un outil d’étude** — `swift run interview quiz` tire des questions au hasard par track et par niveau ; une même seed rejoue le même quiz sur n’importe quelle machine.
- **Un seul format, avec lint** — les questions sont du Markdown simple à la structure fixe, de sorte que les mêmes fichiers alimentent GitHub, la ligne de commande, l’application et la bibliothèque [InterviewBank](#utiliser-la-bibliothèque).

### Contenu

| Track                                             | Sujets                                                                                                                                   | Questions | Avec code testé |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------: | --------------: |
| [iOS](questions/ios)                              | Le langage Swift, mémoire, concurrence, SwiftUI, UIKit et cycle de vie de l’app, données et réseau, tests et outils                      |        58 |              26 |
| [Android](questions/android)                      | Kotlin et coroutines, le framework Android et Jetpack                                                                                    |        22 |               — |
| [Flutter](questions/flutter)                      | Le langage Dart, le framework Flutter                                                                                                    |        22 |              14 |
| [React Native](questions/react-native)            | JavaScript pour React Native, React Native                                                                                               |        22 |              11 |
| [Conception de systèmes](questions/system-design) | Synchronisation hors ligne, fils d’actualité, images, chat, push, OAuth, déploiements progressifs, évolution d’API, nouvelles tentatives |        10 |               — |
| [Comportemental](questions/behavioral)            | STAR, incidents, désaccords, dette technique, mentorat                                                                                   |         8 |               — |

Les extraits Android ne sont pas compilés : la CI ne dispose pas de toolchain Kotlin pour eux, donc ces réponses s’appuient sur la documentation liée. La liste complète des fichiers de sujets se trouve dans [questions/README.md](questions/README.md).

## Démarrage rapide

**1. Récupérer les questions**

```sh
git clone https://github.com/muhittincamdali/mobile-interview-questions.git
cd mobile-interview-questions
```

Il faut Swift 6.2 ou une version ultérieure : Xcode 26 ou ultérieur sur un Mac, ou une [toolchain Swift](https://www.swift.org/install/) sous Linux. Pour simplement lire les fichiers Markdown, il ne faut rien du tout.

**2. Lancer un quiz**

```sh
swift run interview quiz --track ios --level senior --count 3
```

Le premier lancement compile l’outil. Il affiche ensuite trois questions et la seed utilisée :

```console
$ swift run interview quiz --track ios --level senior --count 3 --seed 7
Quiz: 3 of 12 questions · seed 7

1. [IOS-021 · senior · Memory management] Is `autoreleasepool` still useful in Swift?
2. [IOS-029 · senior · Swift concurrency] Where does a `nonisolated async` function run, and what do `nonisolated(nonsending)` and `@concurrent` mean?
3. [IOS-047 · senior · UIKit and the app life cycle] How do you run work in the background on iOS?

Answers: interview show <ID>, or repeat with --seed 7 --answers
```

**3. Vérifier votre réponse**

```sh
swift run interview show IOS-026
```

La commande affiche la réponse, ses références et le test qui vérifie son code ([ConcurrencyTests.swift](Tests/AnswerTests/ConcurrencyTests.swift) pour IOS-026). Ajoutez `--answers` à un quiz avec la même seed pour toutes les afficher d’un coup.

## Commandes

| Commande                                        | Ce qu’elle fait                                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------------------------- |
| `interview list --track flutter --level mid`    | Liste les questions ; accepte aussi `--topic "Swift concurrency"` et `--search actor` |
| `interview show RN-012`                         | Une question avec sa réponse, ses références et son test                              |
| `interview quiz --count 10 --seed 42 --answers` | Un quiz reproductible de 1 à 50 questions                                             |
| `interview stats`                               | Nombre de questions par track et par niveau                                           |
| `interview lint`                                | Vérifie les fichiers de questions ; code de sortie 1 au moindre problème              |

Exécutez `swift run interview --help` pour la liste complète. Les saisies invalides, comme `--count 0`, `--count 1e3` ou un track inconnu, sont signalées avec le code de sortie 2 au lieu de provoquer un plantage.

## Exemple : une réponse vérifiée

Chaque question est une section Markdown avec un ID, un niveau, la réponse et ses sources. Voici le début d’IOS-012 dans [questions/ios/swift-language.md](questions/ios/swift-language.md) :

```markdown
## IOS-012: How do you convert a `Double` to an `Int` without crashing?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

`Int(someDouble)` truncates toward zero, and it **traps** (crashes) when the value is NaN,
infinite or outside `Int`'s range. ...
```

Le test lié exécute chaque conversion de la réponse et échoue si l’une se comporte autrement :

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

L’écriture de ces tests a corrigé des brouillons avant leur publication : par exemple, `Int(1e300)` avec un littéral ne compile tout simplement pas, la réponse montre donc maintenant le trap avec une valeur connue seulement à l’exécution.

## L’application d’étude

[InterviewDeck](Examples) est une application SwiftUI pour iPhone, iPad et Mac, construite sur les mêmes fichiers : elle permet de parcourir et de rechercher dans la banque, de lire les réponses avec leur code, leurs tableaux et leurs références, et de lancer des quiz par track et par niveau.

<p align="center">
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-browse-dark.png"><img src="docs/images/deck-browse-light.png" alt="Liste des questions d’InterviewDeck : 142 questions réparties en six tracks" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-question-dark.png"><img src="docs/images/deck-question-light.png" alt="InterviewDeck affichant la question IOS-026 sur la réentrance des actors, avec son exemple de code" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-quiz-dark.png"><img src="docs/images/deck-quiz-light.png" alt="Carte de quiz d’InterviewDeck pour une question iOS de niveau senior, avec la réponse affichée" width="260"></picture>
</p>

Ouvrez `Examples/InterviewDeck/InterviewDeck.xcodeproj` dans Xcode 26 ou ultérieur, choisissez le scheme **InterviewDeck** et un simulateur d’iPhone ou **My Mac**, puis appuyez sur **Run**. Les captures d’écran sont prises depuis l’application dans un simulateur iOS 27 par [`scripts/capture-screens.sh`](scripts/capture-screens.sh).

## Utiliser la bibliothèque

La bibliothèque `InterviewBank` lit, vérifie (lint), filtre et transforme en quiz les fichiers de questions depuis votre propre code Swift. Ajoutez-la avec Swift Package Manager :

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

La lecture est bornée (1 MiB par fichier, 256 fichiers, 500 questions et 100 problèmes signalés par fichier), et chaque problème de format revient sous la forme d’un `Diagnostic` avec un fichier et une ligne, au lieu d’une exception.

## Documentation

La [documentation d’InterviewBank](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/) couvre l’API et trois articles :

- [Getting Started](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/gettingstarted) — les commandes et l’ajout de la bibliothèque
- [Writing Questions](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/writingquestions) — le format des fichiers, les règles de lint et la manière de vérifier une réponse
- [Building a Study App](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/buildingastudyapp) — intégrer les questions à l’app et afficher les réponses

## Prérequis

| Usage                         | Nécessite                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------- |
| Lire les questions            | Un navigateur ou n’importe quel lecteur Markdown                                |
| Commande `interview`          | Swift 6.2 ou ultérieur (Xcode 26+ sur macOS, ou une toolchain Swift sous Linux) |
| Bibliothèque `InterviewBank`  | Swift 6.2+, iOS 18+ ou macOS 15+                                                |
| Application InterviewDeck     | Xcode 26+, iOS 18+ ou macOS 15+                                                 |
| Tests des réponses Flutter    | Flutter 3.41 ou ultérieur (`cd answers/flutter && flutter test`)                |
| Tests des réponses JavaScript | Node.js 22 ou ultérieur (`cd answers/react-native && npm test`)                 |

## Contribuer

Les corrections et les nouvelles questions sont les bienvenues. Lisez le [guide de contribution](CONTRIBUTING.md) pour le format, les règles de lint et la manière d’ajouter un test à une réponse, ainsi que le [code de conduite](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) avant d’ouvrir une pull request. Signalez les problèmes de sécurité en privé, comme indiqué dans la [politique de sécurité](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Licence

Publié sous licence MIT. Voir [LICENSE](LICENSE).
