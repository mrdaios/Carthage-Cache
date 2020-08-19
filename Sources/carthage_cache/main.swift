import CarthageKit
import Commandant
import Foundation

let registry = CommandRegistry<CarthageError>()
registry.register(PushCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)
registry.main(defaultVerb: helpCommand.verb) { error in
    fputs(error.description + "\n", stderr)
}
