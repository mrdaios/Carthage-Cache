import CarthageKit
import Commandant
import Foundation

print(CommandLine.arguments)

let registry = CommandRegistry<CarthageError>()
registry.register(PushCommand())
registry.register(UploadCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)
registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.description + "\n", stderr)
}
