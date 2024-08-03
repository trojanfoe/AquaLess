//
// ReadmeWindowController.m
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

#import "ReadmeWindowController.h"
#import "MyDocumentController.h"
#import "PagerTextView.h"


@implementation ReadmeWindowController

// init

- (id)initWithReadmeName:(NSString *)fileName controller:(MyDocumentController *)docC
{
  if (self = [super initWithWindowNibName:@"ReadmeWindow"]) {

    readmeName = [fileName retain];
    controller = docC;  // not retained by design

    [controller registerReadmeWindow:readmeName withController:self];

  }
  return self;
}

- (void)dealloc
{
  [controller unregisterReadmeWindow:readmeName];  // just to be sure
  [readmeName release];

  [super dealloc];
}

// post-init

- (void)windowDidLoad
{
  [super windowDidLoad];

  // replace text view from nib with custom subclass (didn't work in Interface Builder...)
  NSRect tvFrame = [display frame];
  tvFrame.origin.x = 0;  // pointless inside a clipview...
  tvFrame.origin.y = 0;
  display = [[[PagerTextView alloc] initWithFrame:tvFrame] autorelease];
  [display setEditable:NO];
  [display setSelectable:YES];
  [display setRichText:YES];
  //[[display layoutManager] replaceTextStorage:[self storage]];
  [scroller setDocumentView:display];

  // set up keyboard event routing
  [[self window] setInitialFirstResponder:display];
  
  // read the file from disk
  NSString *fullPath = [[NSBundle mainBundle] pathForResource:readmeName ofType:@"rtf"];
  [display readRTFDFromFile:fullPath];

  // set window title
  [[self window] setTitle:[NSString stringWithFormat:@"AquaLess %@", readmeName]];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  [[self retain] autorelease];  // make sure we're still around for a short time
  [controller unregisterReadmeWindow:readmeName];
}

@end
