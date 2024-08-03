//
// SmartTextInputParser.m
//
// AquaLess - a less-compatible text pager for Mac OS X
// Copyright (c) 2003 Christoph Pfisterer
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//

#import "SmartTextInputParser.h"
#import "PagerDocument.h"
#import "FontHelper.h"


@implementation SmartTextInputParser

+ (int)priority
{
  return 2;
}

+ (NSString *)name
{
  return @"Text";
}

+ (BOOL)canReadData:(NSData *)partialData
{
  return YES;
}

- (void)parseData:(NSData *)data fromOffset:(unsigned)startOffset toOffset:(unsigned)endOffset
{
    // init style table
    NSDictionary *styles[6];
    styles[0] = nil;
    styles[1] = fontHelperAttr(FontStylePlain);
    styles[2] = fontHelperAttr(FontStyleBold);
    styles[3] = fontHelperAttr(FontStyleUnderline);
    styles[4] = fontHelperAttr(FontStyleBoldUnderline);
    styles[5] = fontHelperAttr(FontStyleInverted);
    
    // parser state
    unsigned offset, state = 0, akkuStyle = 0, lastStyle = 0, x = 0;
    unsigned terminalStyle = 0, terminalStack[16], terminalCount = 0, terminalCode = 0;
    unichar c, lastC = 0;
    NSMutableString *akku = [NSMutableString string];
    
    /*
     state == 0: clean
     state == 1: lastC/lastStyle contains the previous printable character, not yet processed
     state == 2: lastC/lastStyle contains the previous printable character, which was followed by a backspace
     
     In all states, akku may contain chars, which use akkuStyle as their style. Styles:
     0: not set yet, akku is empty
     1: normalAttr
     2: boldAttr
     3: underlineAttr
     4: boldUnderlineAttr
     [invertedAttr doesn't occur]
     */
    
#define CommitCharWithStyle(thechar,thestyle) do { \
        if (akkuStyle && akkuStyle != (thestyle)) { \
            [self addString:akku withAttributes:styles[akkuStyle]]; \
            [akku setString:@""]; \
        } \
        [akku appendString:[NSString stringWithCharacters:&(thechar) length:1]]; \
        x++; \
        akkuStyle = (thestyle); \
    } while(0)
#define CommitFully() if (akkuStyle) { \
        [self addString:akku withAttributes:styles[akkuStyle]]; \
        [akku setString:@""]; \
        akkuStyle = 0; \
    }


    for (offset = startOffset; offset < endOffset; offset++) {
        c = ((const unsigned char *)[data bytes])[offset];
        
        if (state == 3) {
            // inside an escape sequence (or after a single escape)
            if (lastC == 27 && c == '[') {
                // it's a real escape sequence
                terminalCode = 0;
                // state is unchanged
            } else if (lastC == 27) {
                // it's just a stray ESC, put it in the output now
                [self addString:@"ESC" withAttributes:styles[5]];
                lastStyle = 1;
                state = 1;
            } else if (c >= '0' && c <= '9') {
                terminalCode *= 10;
                terminalCode += c - '0';
            } else if (c == ';') {
                // number separator
                terminalCode = 0;
            } else if (c == 'm') {
                // set attributes
                if (terminalCode == 0) {
                    // remove last attribute
                    if (terminalCount > 0)
                        terminalStyle = terminalStack[--terminalCount];
                } else if (terminalCount < 16) {
                    terminalStack[terminalCount++] = terminalStyle;
                    if (terminalCode == 1) {
                        // enable bold
                        if (terminalStyle == 3 || terminalStyle == 4)
                            terminalStyle = 4;
                        else
                            terminalStyle = 2;
                    } else if (terminalCode == 4) {
                        // enable underline
                        if (terminalStyle == 2 || terminalStyle == 4)
                            terminalStyle = 4;
                        else
                            terminalStyle = 3;
                    }
                }
                state = 0;
            } else {
                state = 0;
            }
            lastC = c;
            
        } else if (c == NSBackspaceCharacter) {
            // backspace, used to denote overstriking
            if (state == 1)
                state = 2;
            // lastC is not touched -- important!
            
        } else if (c < 32 || (c >= 127 && c < 128+32)) {
            // non-printable character
            
            if (state == 1) {
                // commit pending character
                if (terminalStyle)
                    lastStyle = terminalStyle;
                CommitCharWithStyle(lastC, lastStyle);
            } // NOTE: in state 2, we assume that the backspace removed the pending char
            state = 0;
            
            // now process the non-printable
            if (c == NSTabCharacter) {
                // add spaces instead
                lastC = ' ';  // for temp purposes, overwritten later by c
                CommitCharWithStyle(lastC, 1);
                for (; x % 8; x++)
                    [akku appendString:[NSString stringWithCharacters:&lastC length:1]];
            } else if (c == NSCarriageReturnCharacter) {
                // set checkpoint _before_ the line break
                CommitFully();
                [self setCheckpoint:offset];
                
                lastC = '\n';  // for temp purposes, overwritten later by c
                CommitCharWithStyle(lastC, 1);
                x = 0;
            } else if (c == NSNewlineCharacter) {
                if (lastC != NSCarriageReturnCharacter) {
                    // set checkpoint _before_ the line break
                    CommitFully();
                    [self setCheckpoint:offset];
                    
                    lastC = '\n';  // for temp purposes, overwritten later by c
                    CommitCharWithStyle(lastC, 1);
                    x = 0;
                }
            } else if (c == 27) {
                // escape, scan what comes after it
                CommitFully();
                state = 3;
            } else {
                // print control char in inverse face
                CommitFully();
                if (c < 32) {  // control sequence
                    [self addString:[NSString stringWithFormat:@"^%c", (int)c ^ 64]
                     withAttributes:styles[5]];
                } else {  // hex
                    [self addString:[NSString stringWithFormat:@"<%X>", (int)c]
                     withAttributes:styles[5]];
                }
            }
            lastC = c;
            
        } else {
            // printable character
            
            if (state == 2) {
                // compute overstrike of c with lastC
                if (c == lastC) {
                    if (c == '_') {
                        // underscore - bs - underscore: is this bold or underline?
                        // -> guess from context
                        if (akkuStyle == 3) {
                            lastStyle = 3;
                        } else {
                            lastStyle = 2;
                        }
                    } else {
                        // bold
                        lastStyle = 2;
                    }
                    // lastC is unmodified
                } else if (c == '_') {
                    // underline, lastC is the real char
                    lastStyle = 3;
                    // lastC is unmodified
                } else if (lastC == '_') {
                    // underline, c is the real char
                    lastStyle = 3;
                    lastC = c;
                } else {
                    // replace
                    lastStyle = 1;
                    lastC = c;
                }
                state = 1;
                
            } else if (state == 1) {
                // normal case, add lastC to akku, move this one to lastC
                if (terminalStyle)
                    lastStyle = terminalStyle;
                CommitCharWithStyle(lastC, lastStyle);
                lastStyle = 1;
                lastC = c;
                // state is unmodified
                
            } else {
                // clean state, just push this char into lastC
                lastStyle = 1;
                lastC = c;
                state = 1;
            }
            
        }
    }
    if (state == 1) {
        // commit pending character
        CommitCharWithStyle(lastC, lastStyle);
    } // NOTE: in state 2, we assume that the backspace removed the pending char
    CommitFully();
    
    // remove the trailing newline if present
    [self chomp];
}

@end
