import Foundation

class MPSwiftLintHelpers {
    
    static var pwd: String? = nil
    
    class func findSwiftFiles(dir: String) -> [String] {
        return executeBashArray(expression: "find \"\(dir)\" -name *.swift | grep -v Tests\\.swift$")
    }
    
    class func executeBash(expression: String) -> String {
        let exitStatus = executeProcess("/bin/bash", arguments: ["-c", "echo \"$(\(expression))\""], shouldPrint: false)
        let outputString = exitStatus.1
        return outputString
    }
    
    class func executeBashArray(expression: String) -> [String] {
        let outputString = executeBash(expression: expression)
        let linesArray = outputString.split(separator: "\n")
        var stringArray: [String] = []
        for line in linesArray {
            stringArray.append(String(line))
        }
        return stringArray
    }
    
    class func executeProcess(_ filepath: String, arguments: [String], shouldPrint: Bool) -> (Int32, String) {
        if #available(OSX 10.13, *) {
            do {
                let task = Process()
                let outputPipe = Pipe()
                let outputHandle = outputPipe.fileHandleForReading
                task.executableURL = URL(fileURLWithPath: filepath)
                task.arguments = arguments
                task.standardOutput = outputPipe
                try task.run()
                task.waitUntilExit()
                let data = outputHandle.readDataToEndOfFile()
                let outputString = String(bytes: data, encoding: .utf8)
                if let outputString = outputString {
                    if shouldPrint && outputString.count > 0 {
                        log(outputString)
                    }
                    return (task.terminationStatus, outputString)
                }
            } catch {
                print("Failed to execute process: \(error)")
            }
        }
        return (1, "")
    }
    
    class func readFile(_ file: String) -> String? {
        guard let contents = FileManager().contents(atPath: file) else { return nil }
        let stringValue = String(bytes: contents, encoding: .utf8)
        return stringValue
    }
    
    class func writeFile(_ file: String, content: String) {
        let data = Data(content.utf8)
        let _ = FileManager().createFile(atPath: file, contents: data, attributes: nil)
    }
    
    class func workingDirectory() -> String {
        if let pwd = pwd {
            return pwd
        }
        if let lintDir = MPSwiftLintHelpers.getEnvironmentVar("MPSWIFTLINT_SWIFTDIR") {
            pwd = lintDir
            return lintDir
        }
        var dir = executeBash(expression: "pwd")
        dir = dir.replacingOccurrences(of: "\n", with: "")
        pwd = dir
        return dir
    }
    
    class func jsonStringify(_ value: Any) -> String? {
        var result: Data? = nil
        do {
            try result = JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
        } catch {
            print("Failed to serialize json: \(error)")
        }
        let stringValue = String(bytes: result!, encoding: .utf8)
        return stringValue
    }
    
    class func jsonStringifyNoSpaces(_ value: Any) -> String? {
        var result: Data? = nil
        do {
            try result = JSONSerialization.data(withJSONObject: value, options: [])
        } catch {
            print("Failed to serialize json: \(error)")
        }
        let stringValue = String(bytes: result!, encoding: .utf8)
        return stringValue
    }
    
    class func jsonParse(_ data: String) -> Any? {
        var result: Any? = nil
        let rawData = data.data(using: .utf8)
        if let rawData = rawData {
            do {
                try result = JSONSerialization.jsonObject(with: rawData, options: .init())
            } catch {
                print("Failed to parse json: \(error)")
                result = nil
            }
            return result
        }
        return nil
    }
    
    class func setEnvironmentVar(name: String, value: String, overwrite: Bool) {
        setenv(name, value, overwrite ? 1 : 0)
    }
    
    class func getEnvironmentVar(_ name: String) -> String? {
        guard let rawValue = getenv(name) else { return nil }
        return String(utf8String: rawValue)
    }
    
    class func verboseLog(_ message: String) -> Void {
        if let _ = MPSwiftLintHelpers.getEnvironmentVar("MPSWIFTLINT_LOG_VERBOSE"){
            log(message)
        }
    }
    
    class func log(_ message: String) -> Void {
        var newMessage = "\(message)\n"
        newMessage = newMessage.replacingOccurrences(of: "\n\n", with: "\n")
        rawLog(newMessage)
    }
    
    class func rawLog(_ message: String) -> Void {
        print(message)
    }
}
