# Editor

## Principles

- The contents only change on either <kbd>Enter</kbd> or
  combinations of at least two keys (such as
  <kbd>Ctrl</kbd>+<kbd>Delete</kbd>).
- The contents shown on canvas always correspond to the contents
  on disk (SD card).
- The contents are always validated, changes cannot be persisted
  unless syntactically valid.
- Editor contents should only change when it's the user's
  explicit aim. Operations which could be interpreted otherwise
  should not make changes as a side effect.
  - Hence, submitting the content only replaces if the highlight
    is the same it was loaded from.

### Keys

| Command                                                           | Keymap                                        |
| :---------------------------------------------------------------- | :-------------------------------------------- |
| Clear terminal                                                    | <kbd>Ctrl</kbd>+<kbd>L</kbd>                  |
| Stop project                                                      | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> |
| Quit project (stop and close)                                     | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Q</kbd> |
| Reset application to initial state                                | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> |
| Exit application                                                  | <kbd>Ctrl</kbd>+<kbd>Esc</kbd>                |
| Pause project                                                     | <kbd>Ctrl</kbd>+<kbd>Pause</kbd>              |
| Toggle edit/run                                                   | <kbd>F9</kbd>                                 |
| **Input**                                                         |
| Move cursor horizontally                                          | <kbd>⇦</kbd>/<kbd>⇨</kbd>                     |
| Move cursor vertically                                            | <kbd>⇧</kbd>/<kbd>⇩</kbd>                     |
| Go back in command history                                        | <kbd>PageUp</kbd>                             |
| Go forward in command history                                     | <kbd>PageDown</kbd>                           |
| Move in history (if in first/last line)                           | <kbd>⇧</kbd>/<kbd>⇩</kbd>                     |
| Jump to start                                                     | <kbd>Home</kbd>                               |
| Jump to end                                                       | <kbd>End</kbd>                                |
| Jump to line start                                                | <kbd>Alt</kbd>+<kbd>Home</kbd>                |
| Jump to line end                                                  | <kbd>Alt</kbd>+<kbd>End</kbd>                 |
| Insert newline                                                    | <kbd>Shift</kbd>+<kbd>Enter ⏎</kbd>           |
| Delete current line                                               | <kbd>Ctrl</kbd>+<kbd>Y</kbd>                  |
| Evaluate input                                                    | <kbd>Enter ⏎</kbd>                            |
| **Editor**                                                        |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; _same as Input, except for:_ |
| Scroll up                                                         | <kbd>PageUp</kbd>                             |
| Scroll down                                                       | <kbd>PageDown</kbd>                           |
| Move selection (if in first/last line)                            | <kbd>⇧</kbd>/<kbd>⇩</kbd>                     |
| Move selection                                                    | <kbd>Ctrl</kbd>+<kbd>⇧</kbd>/<kbd>⇩</kbd>     |
| Replace selection with input                                      | <kbd>Enter ⏎</kbd>                            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; _additionally_               |
| Delete selected block                                             | <kbd>Ctrl</kbd>+<kbd>Delete</kbd>             |
| Delete selected block (if input is empty)                         | <kbd>Ctrl</kbd>+<kbd>Y</kbd>                  |
| Load selected content to input (discards previous content)        | <kbd>Esc</kbd>                                |
| Insert selected content into input                                | <kbd>Shift</kbd>+<kbd>Esc</kbd>               |
| Scroll to start                                                   | <kbd>Ctrl</kbd>+<kbd>PageUp</kbd>             |
| Scroll to end                                                     | <kbd>Ctrl</kbd>+<kbd>PageDown</kbd>           |
| Scroll up by one line                                             | <kbd>Shift</kbd>+<kbd>PageUp</kbd>            |
| Scroll down by one line                                           | <kbd>Shift</kbd>+<kbd>PageDown</kbd>          |
| Move selection to start                                           | <kbd>Ctrl</kbd>+<kbd>Home</kbd>               |
| Move selecion to end                                              | <kbd>Ctrl</kbd>+<kbd>End</kbd>                |
| Wipe input                                                        | <kbd>Ctrl</kbd>+<kbd>W</kbd>                  |
| Duplicate current line                                            | <kbd>Ctrl</kbd>+<kbd>D</kbd>                  |
| Stop editor                                                       | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> |

### Usage

If a project is open, the files inside can be edited or new ones
created. Run the `edit()` command to do so.

![edit](./interface/open_edit.apng)

When a file is opened, the editor is scrolled to the end by
default, and entered input will be appended to the end.

![hello](./interface/hello.apng)

To modify an existing line, navigate there with
<kbd>⇧</kbd>/<kbd>⇩</kbd>. Then load the text by pressing
<kbd>Esc</kbd>, make the desired changes, then send it back with
<kbd>Enter ⏎</kbd>

![capitalized](./interface/hello_cap.apng)

Happy with the modifications now, we can quit by pressing
<kbd>Ctrl-Shift-Q</kbd>

![quit](./interface/quit_editor.apng)
