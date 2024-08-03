//
// HexdumpInputParser.m
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

#import "HexdumpInputParser.h"
#import "PagerDocument.h"
#import "FontHelper.h"


@implementation HexdumpInputParser

+ (int)priority
{
    return 1;
}

+ (NSString *)name
{
    return @"Hex dump";
}

+ (BOOL)canReadData:(NSData *)partialData
{
    return YES;
}

- (void)parseData:(NSData *)data fromOffset:(unsigned)startOffset toOffset:(unsigned)endOffset
{
    unsigned i, offset, linelen;
    const unsigned char *linedata;
    unichar c;
    NSMutableString *line = [[NSMutableString alloc] init];
    NSDictionary *plainAttr = fontHelperAttr(FontStylePlain);
    
    for (offset = startOffset; offset + 16 <= endOffset; offset += 16) {
        // format a complete line
        linedata = ((const unsigned char *)[data bytes]) + offset;
        [line setString:@""];
        
        [line appendFormat:@"%08x  ", offset];
        
        for (i = 0; i < 16; i++) {
            [line appendFormat:@"%02x ", (unsigned)linedata[i]];
            if (i == 7)
                [line appendString:@" "];
        }
        
        [line appendString:@" |"];
        for (i = 0; i < 16; i++) {
            c = linedata[i];
            if (c < 32 || (c >= 127 && c < 128+32))
                c = '.';
            [line appendString:[NSString stringWithCharacters:&c length:1]];
        }
        [line appendString:@"|\n"];
        
        [self addString:line withAttributes:plainAttr];
    }
    
    // set checkpoint after last complete line
    [self setCheckpoint:offset];
    
    if (offset < endOffset) {
        // there actually is (incomplete) data for the last line
        linelen = endOffset - offset;
        linedata = ((const unsigned char *)[data bytes]) + offset;
        [line setString:@""];
        
        [line appendFormat:@"%08x  ", offset];
        
        for (i = 0; i < linelen; i++) {
            [line appendFormat:@"%02x ", (unsigned)linedata[i]];
            if (i == 7)
                [line appendString:@" "];
        }
        for (; i < 16; i++) {
            if (i == 7)
                [line appendString:@"    "];
            else
                [line appendString:@"   "];
        }
        
        [line appendString:@" |"];
        for (i = 0; i < linelen; i++) {
            c = linedata[i];
            if (c < 32 || (c >= 127 && c < 128+32))
                c = '.';
            [line appendString:[NSString stringWithCharacters:&c length:1]];
        }
        [line appendString:@"|\n"];
        
        [self addString:line withAttributes:plainAttr];
        
        offset += linelen;
    }
    
    [line release];
    
    // add the final offset on the last line, no newline
    [self addString:[NSString stringWithFormat:@"%08x", offset] withAttributes:plainAttr];
}

@end
