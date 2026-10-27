<!-- i18n-source: README.md@44f564ab04495f1a227681c77f2b694dcbacd7b3 status=reviewed -->
<!-- brand:start -->

<p align="center"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/banner-light.svg" alt="Mobile Interview Questions: Interview questions for iOS, Android, Flutter and React Native, with sourced answers and tested code."></picture></p>

<!-- lang-selector:start -->
<p align="center"><a href="README.md">English</a> · <a href="README.tr.md">Türkçe</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português (Brasil)</a> · <a href="README.ru.md">Русский</a></p>
<!-- lang-selector:end -->

<p align="center">
<a href="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml"><img src="https://github.com/muhittincamdali/mobile-interview-questions/actions/workflows/ci.yml/badge.svg" alt="Estado de CI"></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/releases"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-version-light.svg" alt="Última versión: v1.0.0"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-platforms-light.svg" alt="Plataformas compatibles: iOS 18+ · macOS 15+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/Package.swift"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-language-light.svg" alt="Versión del lenguaje: Swift 6.2+"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/blob/main/LICENSE"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/badge-license-light.svg" alt="Licencia: MIT"></picture></a>
</p>

<p align="center">
<a href="#inicio-rápido"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-start-es-light.svg" alt="Empezar"></picture></a>
<a href="https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-docs-es-light.svg" alt="Documentación"></picture></a>
<a href="https://github.com/muhittincamdali/mobile-interview-questions/tree/main/Examples"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-es-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-es-light.svg"><img src="https://raw.githubusercontent.com/muhittincamdali/mobile-interview-questions/main/.github/brand/button-examples-es-light.svg" alt="Ejemplos"></picture></a>
</p>

> Esta es una traducción del README en inglés. Si hay diferencias, la versión en inglés es la vigente.

<!-- brand:end -->
Preguntas y respuestas de entrevista para desarrolladores móviles: iOS, Android, Flutter, React Native, diseño de sistemas móviles y rondas de comportamiento. El banco tiene 142 preguntas, cada una etiquetada como junior, mid o senior, y cada respuesta técnica enlaza con la fuente primaria en la que se apoya: la documentación de Apple, Android, Flutter, Dart, Kotlin y React Native, las propuestas de Swift Evolution, MDN o un RFC. 51 respuestas incluyen código que una prueba ejecuta en CI, de modo que las afirmaciones que hacen (un actor es reentrante, `Int(Double.nan)` hace trap, un widget const no se reconstruye, `forEach` no espera) se comprueban en lugar de repetirse.

Puedes leer las preguntas aquí en GitHub, ponerte a prueba en la terminal con el comando `interview` o estudiarlas con la app InterviewDeck para iPhone, iPad y Mac.

## Lo más destacado

- **Plataformas actuales** — el modo de lenguaje Swift 6 con aislamiento main-actor por defecto y `@concurrent`, el ciclo de vida basado en scenes que deben adoptar las apps compiladas con el SDK de iOS 27, los cambios de Android 16 para pantallas grandes y predictive back, los patrones y los extension types de Dart 3, y la New Architecture de React Native.
- **Respuestas que puedes comprobar** — toda respuesta técnica cita una fuente primaria, y el linter rechaza las que no lo hacen.
- **Código probado** — las respuestas de Swift se ejecutan con Swift Testing en macOS y en un simulador de iPhone, las de Dart y Flutter con `flutter test` (incluidas las pruebas de widgets) y las de JavaScript con `node --test`. Cada prueba lleva el nombre de la pregunta que comprueba.
- **Una herramienta de estudio** — `swift run interview quiz` elige preguntas al azar por track y nivel; con la misma seed se repite el mismo cuestionario en cualquier máquina.
- **Un solo formato, con lint** — las preguntas son Markdown simple con una estructura fija, así que los mismos archivos alimentan GitHub, la línea de comandos, la app y la biblioteca [InterviewBank](#usar-la-biblioteca).

### Qué contiene

| Track                                         | Temas                                                                                                                        | Preguntas | Con código probado |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------: | -----------------: |
| [iOS](questions/ios)                          | El lenguaje Swift, memoria, concurrencia, SwiftUI, UIKit y el ciclo de vida de la app, datos y redes, pruebas y herramientas |        58 |                 26 |
| [Android](questions/android)                  | Kotlin y corrutinas, el framework de Android y Jetpack                                                                       |        22 |                  — |
| [Flutter](questions/flutter)                  | El lenguaje Dart, el framework Flutter                                                                                       |        22 |                 14 |
| [React Native](questions/react-native)        | JavaScript para React Native, React Native                                                                                   |        22 |                 11 |
| [Diseño de sistemas](questions/system-design) | Sincronización sin conexión, feeds, imágenes, chat, push, OAuth, despliegues graduales, evolución de APIs, reintentos        |        10 |                  — |
| [Comportamiento](questions/behavioral)        | STAR, incidentes, desacuerdos, deuda técnica, mentoría                                                                       |         8 |                  — |

Los fragmentos de Android no se compilan: CI no tiene una toolchain de Kotlin para ellos, así que esas respuestas se apoyan en la documentación enlazada. La lista completa de archivos de temas está en [questions/README.md](questions/README.md).

## Inicio rápido

**1. Consigue las preguntas**

```sh
git clone https://github.com/muhittincamdali/mobile-interview-questions.git
cd mobile-interview-questions
```

Necesitas Swift 6.2 o posterior: Xcode 26 o posterior en un Mac, o una [toolchain de Swift](https://www.swift.org/install/) en Linux. Para leer solo los archivos Markdown no necesitas nada.

**2. Ejecuta un cuestionario**

```sh
swift run interview quiz --track ios --level senior --count 3
```

La primera ejecución compila la herramienta. Después muestra tres preguntas y la seed que usó:

```console
$ swift run interview quiz --track ios --level senior --count 3 --seed 7
Quiz: 3 of 12 questions · seed 7

1. [IOS-021 · senior · Memory management] Is `autoreleasepool` still useful in Swift?
2. [IOS-029 · senior · Swift concurrency] Where does a `nonisolated async` function run, and what do `nonisolated(nonsending)` and `@concurrent` mean?
3. [IOS-047 · senior · UIKit and the app life cycle] How do you run work in the background on iOS?

Answers: interview show <ID>, or repeat with --seed 7 --answers
```

**3. Comprueba tu respuesta**

```sh
swift run interview show IOS-026
```

Esto muestra la respuesta, sus referencias y la prueba que comprueba su código ([ConcurrencyTests.swift](Tests/AnswerTests/ConcurrencyTests.swift) para IOS-026). Añade `--answers` a un cuestionario con la misma seed para mostrarlas todas a la vez.

## Comandos

| Comando                                         | Qué hace                                                                         |
| ----------------------------------------------- | -------------------------------------------------------------------------------- |
| `interview list --track flutter --level mid`    | Lista preguntas; también admite `--topic "Swift concurrency"` y `--search actor` |
| `interview show RN-012`                         | Una pregunta con su respuesta, referencias y prueba                              |
| `interview quiz --count 10 --seed 42 --answers` | Un cuestionario repetible de 1 a 50 preguntas                                    |
| `interview stats`                               | Preguntas por track y nivel                                                      |
| `interview lint`                                | Comprueba los archivos de preguntas; código de salida 1 ante cualquier problema  |

Ejecuta `swift run interview --help` para ver la lista completa. Las entradas no válidas, como `--count 0`, `--count 1e3` o un track desconocido, se notifican con código de salida 2 en lugar de provocar un fallo.

## Ejemplo: una respuesta verificada

Cada pregunta es una sección de Markdown con un ID, un nivel, la respuesta y sus fuentes. Este es el comienzo de IOS-012 en [questions/ios/swift-language.md](questions/ios/swift-language.md):

```markdown
## IOS-012: How do you convert a `Double` to an `Int` without crashing?

**Level:** mid · **Verified by:** [SwiftLanguageTests](../../Tests/AnswerTests/SwiftLanguageTests.swift)

`Int(someDouble)` truncates toward zero, and it **traps** (crashes) when the value is NaN,
infinite or outside `Int`'s range. ...
```

La prueba enlazada ejecuta todas las conversiones de la respuesta y falla si alguna se comporta de otra manera:

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

Escribir estas pruebas corrigió borradores antes de publicarlos: por ejemplo, `Int(1e300)` con un literal ni siquiera compila, así que ahora la respuesta muestra el trap con un valor que solo se conoce en tiempo de ejecución.

## La app de estudio

[InterviewDeck](Examples) es una app SwiftUI para iPhone, iPad y Mac creada a partir de los mismos archivos: permite explorar y buscar en el banco, leer las respuestas con su código, tablas y referencias, y hacer cuestionarios por track y nivel.

<p align="center">
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-browse-dark.png"><img src="docs/images/deck-browse-light.png" alt="Lista de preguntas de InterviewDeck: 142 preguntas en seis tracks" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-question-dark.png"><img src="docs/images/deck-question-light.png" alt="InterviewDeck mostrando la pregunta IOS-026 sobre la reentrancia de los actores, con su ejemplo de código" width="260"></picture>
<picture><source media="(prefers-color-scheme: dark)" srcset="docs/images/deck-quiz-dark.png"><img src="docs/images/deck-quiz-light.png" alt="Tarjeta de cuestionario de InterviewDeck para una pregunta de iOS de nivel senior con la respuesta visible" width="260"></picture>
</p>

Abre `Examples/InterviewDeck/InterviewDeck.xcodeproj` en Xcode 26 o posterior, elige el scheme **InterviewDeck** y un simulador de iPhone o **My Mac**, y pulsa **Run**. Las capturas de pantalla se toman de la app en un simulador de iOS 27 con [`scripts/capture-screens.sh`](scripts/capture-screens.sh).

## Usar la biblioteca

La biblioteca `InterviewBank` lee, comprueba con lint, filtra y convierte en cuestionarios los archivos de preguntas desde tu propio código Swift. Añádela con Swift Package Manager:

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

La lectura está acotada (1 MiB por archivo, 256 archivos, 500 preguntas por archivo), y cada problema de formato se devuelve como un `Diagnostic` con archivo y línea en lugar de una excepción.

## Documentación

La [documentación de InterviewBank](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/) cubre la API y tres artículos:

- [Getting Started](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/gettingstarted) — los comandos y cómo añadir la biblioteca
- [Writing Questions](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/writingquestions) — el formato de archivo, las reglas de lint y cómo verificar una respuesta
- [Building a Study App](https://muhittincamdali.github.io/mobile-interview-questions/documentation/interviewbank/buildingastudyapp) — cómo incluir las preguntas en la app y mostrar las respuestas

## Requisitos

| Uso                                 | Necesita                                                                      |
| ----------------------------------- | ----------------------------------------------------------------------------- |
| Leer las preguntas                  | Un navegador o cualquier visor de Markdown                                    |
| Comando `interview`                 | Swift 6.2 o posterior (Xcode 26+ en macOS, o una toolchain de Swift en Linux) |
| Biblioteca `InterviewBank`          | Swift 6.2+, iOS 18+ o macOS 15+                                               |
| App InterviewDeck                   | Xcode 26+, iOS 18+ o macOS 15+                                                |
| Pruebas de respuestas de Flutter    | Flutter 3.41 o posterior (`cd answers/flutter && flutter test`)               |
| Pruebas de respuestas de JavaScript | Node.js 22 o posterior (`cd answers/react-native && npm test`)                |

## Contribuir

Las correcciones y las preguntas nuevas son bienvenidas. Lee la [guía de contribución](CONTRIBUTING.md) para conocer el formato, las reglas de lint y cómo añadir una prueba a una respuesta, y el [código de conducta](https://github.com/muhittincamdali/.github/blob/main/CODE_OF_CONDUCT.md) antes de abrir una pull request. Informa de los problemas de seguridad de forma privada, como se describe en la [política de seguridad](https://github.com/muhittincamdali/.github/blob/main/SECURITY.md).

## Licencia

Publicado bajo la licencia MIT. Consulta [LICENSE](LICENSE).
