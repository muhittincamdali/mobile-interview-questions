import Foundation
import InterviewCLI

let tool = InterviewTool(currentDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))
var output = FileStream(.standardOutput)
var errors = FileStream(.standardError)
let status = tool.run(Array(CommandLine.arguments.dropFirst()), output: &output, errors: &errors)
output.flush()
errors.flush()
exit(status)
