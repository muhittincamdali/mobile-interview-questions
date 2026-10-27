import Foundation
import InterviewCLI

let tool = InterviewTool(currentDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
let result = tool.run(Array(CommandLine.arguments.dropFirst()))
FileHandle.standardOutput.write(Data(result.standardOutput.utf8))
FileHandle.standardError.write(Data(result.standardError.utf8))
exit(result.status)
