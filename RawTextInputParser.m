//
// RawTextInputParser.m
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

#import "RawTextInputParser.h"
#import "PagerDocument.h"
#import "FontHelper.h"


@implementation RawTextInputParser

+ (int)priority
{
    return 1;
}

+ (NSString *)name
{
    return @"Raw Text";
}

+ (BOOL)canReadData:(NSData *)partialData
{
    return YES;
}

- (void)parseData:(NSData *)data fromOffset:(unsigned)startOffset toOffset:(unsigned)endOffset
{
    // init style table
    NSDictionary *plainAttr = fontHelperAttr(FontStylePlain);
    NSDictionary *invertedAttr = fontHelperAttr(FontStyleInverted);
    
    // parser state
    unsigned offset;
    unichar c, lastC = 0;
    NSMutableString *akku = [NSMutableString string];
    
    for (offset = startOffset; offset < endOffset; offset++) {
        c = ((const unsigned char *)[data bytes])[offset];
        
        if (c < 32 || (c >= 127 && c < 128+32)) {
            // non-printable character
            
            [self addString:akku withAttributes:plainAttr];
            [akku setString:@""];
            
            if (c == NSCarriageReturnCharacter) {
                // set checkpoint _before_ the line break
                [self setCheckpoint:offset];
                
                lastC = '\n';  // for temp purposes, overwritten later by c
                [akku appendString:[NSString stringWithCharacters:&lastC length:1]];
            } else if (c == NSNewlineCharacter) {
                if (lastC != NSCarriageReturnCharacter) {
                    // set checkpoint _before_ the line break
                    [self setCheckpoint:offset];
                    
                    lastC = '\n';  // for temp purposes, overwritten later by c
                    [akku appendString:[NSString stringWithCharacters:&lastC length:1]];
                }
            } else {
                // print control char in inverse face
                if (c == 27) {  // escape
                    [self addString:@"ESC" withAttributes:invertedAttr];
                } else if (c < 32) {  // control sequence
                    [self addString:[NSString stringWithFormat:@"^%c", (int)c ^ 64]
                     withAttributes:invertedAttr];
                } else {  // hex
                    [self addString:[NSString stringWithFormat:@"<%X>", (int)c]
                     withAttributes:invertedAttr];
                }
            }
            
        } else {
            // printable character
            [akku appendString:[NSString stringWithCharacters:&c length:1]];
            
        }
        lastC = c;
    }
    [self addString:akku withAttributes:plainAttr];
    
    // remove the trailing newline if present
    [self chomp];
}

@end
