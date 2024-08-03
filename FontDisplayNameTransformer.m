//
// FontDisplayNameTransformer.m
//
// AquaLess - a less-compatible text pager for Mac OS X
// Copyright (c) 2003-2005 Christoph Pfisterer
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

#import "FontDisplayNameTransformer.h"


@implementation FontDisplayNameTransformer

+ (Class)transformedValueClass
{
    return [NSData self];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)archivedObject
{
    if (archivedObject == nil)
        return nil;
    NSFont *font = (NSFont *)[NSUnarchiver unarchiveObjectWithData:archivedObject];
    return [NSString stringWithFormat:@"%@, %.1f", [font displayName], [font pointSize]];
}

@end
