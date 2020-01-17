## reedline.vim

### Overview

Some little bash/readline style cmdline shortcuts for vim.

### Mappings

| Shortcut | Description |
| :---: | :--- |
| <kbd>Ctrl</kbd>-<kbd>a</kbd> | Jump to start of line |
| <kbd>Ctrl</kbd>-<kbd>e</kbd> | Jump to end of line |
| <kbd>Ctrl</kbd>-<kbd>k</kbd> | Delete everything from cursor to end of line |
| <kbd>Ctrl</kbd>-<kbd>p</kbd> | Cycle up through command history |
| <kbd>Ctrl</kbd>-<kbd>n</kbd> | Cycle down through command history |
| <kbd>Ctrl</kbd>-<kbd>b</kbd> | Move one character left |
| <kbd>Ctrl</kbd>-<kbd>f</kbd> | Move one character right |
| <kbd>Alt</kbd>-<kbd>b</kbd> | Move one word left |
| <kbd>Alt</kbd>-<kbd>f</kbd> | Move one word right |
| <kbd>Alt</kbd>-<kbd>d</kbd> | Delete word after cursor |
| <kbd>Alt</kbd>-<kbd>BkSpace</kbd> | Rubout word |
| <kbd>Ctrl</kbd>-<kbd>w</kbd> | Rubout word [or space-delimited word, optionally] |
| <kbd>Ctrl</kbd>-<kbd>u</kbd> | Delete everything from cursor to start of line |
| <kbd>Ctrl</kbd>-<kbd>d</kbd> | Delete character |
| <kbd>Alt</kbd>-<kbd>=</kbd>, <kbd>Alt</kbd>-<kbd>?</kbd> | Display command completion options |
| <kbd>Alt</kbd>-<kbd>l</kbd> | Make next word lowercase |
| <kbd>Alt</kbd>-<kbd>u</kbd> | Make next word UPPERCASE |
| <kbd>Alt</kbd>-<kbd>c</kbd> | Make next word Capitalized |
| <kbd>Ctrl</kbd>-<kbd>y</kbd> | "Yank" (put/paste) most recently deleted word |
| <kbd>Ctrl</kbd>-<kbd>t</kbd> | Transpose characters |
| <kbd>Alt</kbd>-<kbd>t</kbd> | Transpose words |

### Configuration

Once installed, the variable `g:space_delimited_C_w` may be set to a nonzero
value to force <kbd>Ctrl</kbd>-<kbd>w</kbd> to behave like it normally does in
bash (i.e. rubout the word up to the previous space). Otherwise it will act
identically to <kbd>Alt</kbd>-<kbd>BkSpace</kbd> - as it does by default in zsh,
for instance.
