# Trigger-Key, The Macro-Engine Dynamic Loader for Hotkeys Hotstrings
The Macro Engine uses simple, human-readable tags to define automation commands.
Users can trigger macros using Trigger Text or Trigger Keys, and perform actions like launching apps, typing text, waiting, and showing custom messages.
This system is easy to edit, fully modular, and powerful for productivity scripting that allows users to load custom Hotkeys, Hotstrings, and automation modules at runtime—without editing the main script.

## 🧩 Command Format Overview

| KEY | Commands |
|--|--|
|\; Comment | Lines starting with semicolon are ignored |
|\<TT> | Trigger Text (typed word triggers macro) |
|\<KT> | Trigger Key (example: ^q → Ctrl+Q) |
|\<LAUNCH> | Launch programs or open folders |
|\<MSGBOX> | Show custom message box |
|\<WAIT 1000> | Wait/pause for given milliseconds |
|\<DE 100> | Delay between each typed character |
|\<SEND> | Type text in a single line (no auto newline) |
|\<START> | Beginning of macro commands |
|\<END> | End of macro commands |
|Normal text | Multi-line typing block between <START> and <END> 

## 🧱 **Basic Structure**
***Every macro looks like this:***

***\<TT>*** trigger-word or <KT>^q

\<START>

... commands here ...

\<END>
