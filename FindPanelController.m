//
// FindPanelController.m
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

#import "FindPanelController.h"
#import "PagerWindowController.h"


@implementation FindPanelController

// init

- (id)initWithController:(PagerWindowController *)winC
{
  if (self = [super initWithWindowNibName:@"FindPanel"]) {
    parentController = winC;
  }
  return self;
}

- (void)dealloc
{
  //[[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

// action

- (IBAction)dismissOk:(id)sender
{
  [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)dismissCancel:(id)sender
{
  [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

// sheet starting

- (void)runOnWindow:(NSWindow *)parentWindow
{
  [NSApp beginSheet:[self window]
     modalForWindow:parentWindow
      modalDelegate:self
     didEndSelector:@selector(findDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}

- (void)setDirection:(BOOL)backwards
{
  if (backwards) {
    [backwardsControl performClick:self];
  } else {
    [forwardsControl performClick:self];
  }
}

// sheet termination

- (void)findDidEnd:(NSWindow *)sheet
        returnCode:(int)returnCode
       contextInfo:(void *)contextInfo
{
  [sheet orderOut:self];

  if (returnCode == NSOKButton) {
    NSString *pattern = [patternControl stringValue];

    int flags = 0;
    if ([backwardsControl intValue])
      flags |= SearchDirectionBackwards;
    else
      flags |= SearchDirectionForwards;
    if ([caseControl intValue])
      flags |= SearchCaseInsensitive;
    else
      flags |= SearchCaseSensitive;
    if ([regexControl intValue])
      flags |= SearchRegexEnabled;
    else
      flags |= SearchRegexDisabled;

    [parentController findPanelDidEndWithPattern:pattern flags:flags];
  }
}

@end
