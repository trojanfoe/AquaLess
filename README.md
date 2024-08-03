# AquaLess

This is an update to [AquaLess](https://sourceforge.net/projects/aqualess/) written by Christoph Pfisterer.

It has been updated in response to this [StackOverflow Question](https://stackoverflow.com/questions/78828624/how-do-i-update-an-ancient-mac-app-aqualess) to compile with Xcode 15, however the use of many deprecated APIs and classes remain.

Fixing the project involved:

- Using `ibtool file.nib --upgrade --write file.xib` to upgrade the NIB files to XIB files.
- The use of `[NSLayoutManager defaultLineHeightForFont:]` instead of `[NSFont defaultLineHeightForFont]`.
- Hacking the `.xcodeproj` to remove the reference to the MacOSX10.4.sdk.
- The `aless` command line tool is now installed into `/usr/local/bin` and not `/usr/bin`.

# Original Credits:

Written by Christoph Pfisterer <chrisp@users.sourceforge.net>.

Regular Expression matching uses the AGRegex class by Aram Greenman and the PCRE library by Philip Hazel.

Application icon based on original art by Diana Todd, used with permission.

AquaLess is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. Select “AquaLess License” from the “Help” menu for more information.
 

# Original Readme file:

AquaLess ReadMe

AquaLess is a text pager for Mac OS X. It allows you to browse plain text files and – more importantly – text output from Unix command line tools. AquaLess is a Cocoa replacement for the “less” command, which is constrained to the terminal window. AquaLess opens a separate window for each text, so you can keep working in the terminal while you read.

Installation Instructions
Copy the AquaLess application to a convenient location on your hard disk, e.g. the “Applications” folder.

The first time you run AquaLess, it will offer to install the “aless” command line tool in a system directory. This makes it available in Terminal without further configuration, but requires an administrator password.

Basic Usage
It is possible to open files of any kind through the “File” menu, but the recommended way to work with AquaLess is from the command line. You can use the “aless” command in the same basic way as the “less” command. You can specify one or several files to display:

aless README NEWS

Or you can pipe the output from another command into aless for comfortable reading:

ps ax | aless

Automatic Usage
Some commands (e.g. “man”) automatically invoke a text pager for their output. These commands get the name of the pager to use from the environment variable PAGER. To use AquaLess with these programs, set the variable to “aless”, like this:

setenv PAGER aless	(for tcsh)

export PAGER=aless	(for bash)

If you are used to typing “less”, you can re-define that using an alias:

alias less aless	(for tcsh)

alias less=aless	(for bash)

All of these customizations can be made permanent by adding the command to the shell’s startup file. For tcsh, use .cshrc in your home directory, for bash .bashrc is appropriate.

About Formats
AquaLess supports the special codes used by “man” to encode bold and underlined words in plain text. This processing can be disabled using the popup menu at the bottom of each text window. The popup also allows you to select a “Hex dump” mode, which is more suitable for binary (i.e. non-text) files.

Keyboard Commands
AquaLess supports a range of keyboard commands in an effort to be less-compatible. You can use them with or without the Control key pressed. The commands are:

e, j, Return, Enter, Down Arrow Key
Scrolls down by one line.
y, p, k, Up Arrow Key
Scrolls up by one line.
f, z, v, Page Down Key, Space
Scrolls down by one page.
b, w, Page Up Key, Shift-Space
Scrolls up by one page.
d
Scrolls down by half a page.
u
Scrolls up by half a page.
g, <, Home Key
Scrolls to the beginning of the file.
G (i.e. Shift-g), >, End Key
Scrolls to the end of the file.
F (i.e. Shift-f)
Scrolls to the end of the file and keeps scrolling down as data is appended to the file. This emulates the behavior of “tail -f”. To cancel automatic scrolling, use any other scrolling command to move away from the end of the file.
q
Closes the window.
/
Opens the find dialog, set for searching forwards.
?
Opens the find dialog, set for searching backwards.
n
Searches again in the same direction as last set in the find dialog.
N (i.e. Shift-n)
Searches again, but in the opposite direction as last set in the find dialog.

Getting the Source
AquaLess is “Open Source” software. In addition to the program, you also get the full source code, so you can modify it to your liking. In fact, the license used for AquaLess effectively requires everyone who distributes the program to distribute the source along with it. If you didn’t get the source together with the binary, you can download it from <http://aqualess.sourceforge.net/>.

Version History
Version 1.6:
•	Bug fix for files sent from the “aless” tool being truncated
•	Now requires Mac OS X 10.4 or higher

Version 1.5:
•	Font and text color can be set through the Preferences window
•	Built as a Universal Binary
•	Now requires Mac OS X 10.3.9 or higher

Version 1.4:
•	Fixed a memory leak (thanks to Dave Dribin)
•	Added a title option to the command line tool
•	Fixed command line tool installation to be robust against prebinding and friends

Version 1.3:
•	Added searching for regular expressions
•	Added parsing of certain terminal escape sequences

Version 1.2:
•	Fixed window resizes
•	Fixed Find sheet reappearing bug

Version 1.1:
•	Added search function; only plain text matches for now
•	Fixed display of certain man pages
•	File loading is now fully incremental and always watches for newly appended data (part one of “tail -f” emulation)
•	Added an auto-scrolling mode (part two of “tail -f” emulation)
•	Added help (-h) and version (-v) switches to the command line tool
•	Other minor changes

Version 1.0:
First public release.

Credits
AquaLess was written by Christoph Pfisterer <chrisp@users.sourceforge.net>. Regular Expression matching uses the AGRegex class by Aram Greenman and the PCRE library by Philip Hazel. The application icon is based on original art by Diana Todd, used with permission.

Have fun!
