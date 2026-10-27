// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MobileInterviewQuestions",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "InterviewBank", targets: ["InterviewBank"]),
        .executable(name: "interview", targets: ["interview"])
    ],
    targets: [
        .target(name: "InterviewBank"),
        .target(name: "InterviewCLI", dependencies: ["InterviewBank"]),
        .executableTarget(name: "interview", dependencies: ["InterviewCLI"]),
        .testTarget(name: "InterviewBankTests", dependencies: ["InterviewBank"]),
        .testTarget(name: "InterviewCLITests", dependencies: ["InterviewCLI"])
    ]
)
