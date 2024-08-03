//
// PagerWindowController.m
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

#import "PagerWindowController.h"
#import "PagerDocument.h"
#import "PagerTextView.h"
#import "FindPanelController.h"
#import "FontHelper.h"
#import "AGRegex.h"
#import "InputParser.h"


#define DropPatternMask SearchCaseMask


@implementation PagerWindowController

// init

- (id)init
{
  if (self = [super initWithWindowNibName:@"PagerDocument"]) {
    [self setShouldCloseDocument:YES];
    findPanel = nil;
    lastPattern = nil;
    lastRegex = nil;
    lastFlags = 0;
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (findPanel != nil)
    [findPanel release];
  if (lastPattern != nil)
    [lastPattern release];
  if (lastRegex != nil)
    [lastRegex release];

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
  [[display layoutManager] replaceTextStorage:[self storage]];
  [scroller setDocumentView:display];

  // scroll and resize by full character cells
  NSSize cell = fontHelperCellSize();
  [scroller setVerticalLineScroll:cell.height];
  [scroller setVerticalPageScroll:cell.height];  // page scrolls keep one line
  [scroller setHorizontalLineScroll:cell.width];
  [scroller setHorizontalPageScroll:cell.width];  // page scrolls keep one line
  [[self window] setResizeIncrements:cell];

  /*
  // add space at top and bottom, like in Terminal
  NSSize inset = [display textContainerInset];
  inset.height += 3;
  [display setTextContainerInset:inset];
  */

  // fill formats popup
  [formatPopup removeAllItems];
  int i;
  NSArray *allFormats = [PagerDocument allFormats];
  for (i = 0; i < [allFormats count]; i++) {
    Class format = [allFormats objectAtIndex:i];
    [formatPopup addItemWithTitle:[format name]];
  }

  // observe the document for changes in status
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(updateStatus:)
                                               name:StatusChangedNotification
                                             object:[self document]];

  // set up notifications for tail lock
  [[NSNotificationCenter defaultCenter] addObserver:display
                                           selector:@selector(textAppended:)
                                               name:NSViewFrameDidChangeNotification
                                             object:display];
  [display setPostsFrameChangedNotifications:YES];

  // update the status line
  [self updateStatus:nil];

  // set up keyboard event routing
  [[self window] setInitialFirstResponder:display];
}

// access

- (NSTextStorage *)storage
{
  return [[self document] storage];
}

// status display

- (void)updateStatus:(NSNotification *)notification
{
  [status setStringValue:[[self document] statusLine]];

  Class currentFormat = [[self document] currentFormat];
  if (currentFormat != nil)
    [formatPopup selectItemWithTitle:[currentFormat name]];
}

// format selection

- (IBAction)changeFormat:(id)sender
{
  NSString *formatName = [formatPopup titleOfSelectedItem];
  Class currentFormat = [[self document] currentFormat];
  if (currentFormat != nil)
    if ([formatName isEqual:[currentFormat name]])
      return;  // no change

  int i;
  NSArray *allFormats = [PagerDocument allFormats];
  for (i = 0; i < [allFormats count]; i++) {
    Class format = [allFormats objectAtIndex:i];
    if ([formatName isEqual:[format name]]) {
      [[self document] setCurrentFormat:format];
      break;
    }
  }
}

// find panel actions

- (FindPanelController *)findPanel;
{
  if (findPanel == nil) {
    findPanel = [[FindPanelController alloc] initWithController:self];
  }
  return findPanel;
}

- (IBAction)showFindPanel:(id)sender
{
  [[self findPanel] runOnWindow:[self window]];
}

- (void)showFindPanelBackwards:(BOOL)back
{
  [[self findPanel] setDirection:back];
  [[self findPanel] runOnWindow:[self window]];
}

- (IBAction)findAgainForwards:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  int flags = lastFlags & ~SearchDirectionMask;
  flags |= SearchDirectionForwards;
  lastFlags = flags;
  [self findPatternWithFlags:flags];
}

- (IBAction)findAgainBackwards:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  int flags = lastFlags & ~SearchDirectionMask;
  flags |= SearchDirectionBackwards;
  lastFlags = flags;
  [self findPatternWithFlags:flags];
}

- (IBAction)findAgainSameDirection:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  int flags = lastFlags;
  [self findPatternWithFlags:flags];
}

- (IBAction)findAgainOtherDirection:(id)sender
{
  if (lastPattern == nil || [lastPattern length] == 0) {
    NSBeep();
    return;
  }

  int flags = lastFlags & ~SearchDirectionMask;
  if ((lastFlags & SearchDirectionMask) == SearchDirectionForwards)
    flags |= SearchDirectionBackwards;
  else
    flags |= SearchDirectionForwards;
  [self findPatternWithFlags:flags];
}

- (void)findPanelDidEndWithPattern:(NSString *)pattern flags:(int)flags
{
  if (lastPattern != nil) {
    if ((![lastPattern isEqualToString:pattern]
         || (flags & DropPatternMask) != (lastFlags & DropPatternMask))
        && lastRegex != nil) {
      // pattern string (or case option) has changed, release cached regex object
      [lastRegex autorelease];
      lastRegex = nil;
    }
    [lastPattern autorelease];
  }
  lastPattern = [pattern retain];
  lastFlags = flags;

  [self findPatternWithFlags:flags];
}

// low-level search

- (void)findPatternWithFlags:(int)flags
{
  NSString *pattern = lastPattern;
  NSString *haystack = [[self storage] mutableString];
  NSRange searchRange, range;
  NSRange startRange = [display selectedRange];

  // find options
  unsigned options = 0;
  if ((flags & SearchRegexMask) == SearchRegexEnabled) {
    // find options for the AGRegex search
    if ((flags & SearchCaseMask) == SearchCaseInsensitive)
      options |= AGRegexCaseInsensitive;

    // create the pattern if necessary
    if (lastRegex == nil) {
      lastRegex = [[AGRegex alloc] initWithPattern:pattern options:options];
    }
  } else {
    // find options for the NSString search
    if ((flags & SearchCaseMask) == SearchCaseInsensitive)
      options |= NSCaseInsensitiveSearch;
  }

  BOOL inclusive = NO;
  if (startRange.length == 0) {
    startRange = [display visibleRange];
    inclusive = YES;
  }

  if ((flags & SearchDirectionMask) == SearchDirectionForwards) {
    // forwards
    if (inclusive)
      searchRange.location = startRange.location;
    else
      searchRange.location = NSMaxRange(startRange);
    searchRange.length = [haystack length] - searchRange.location;

    if ((flags & SearchRegexMask) == SearchRegexEnabled) {
      AGRegexMatch *match = [lastRegex findInString:haystack range:searchRange];
      if (match != nil)
        range = [match range];
      else
        range.length = 0;
    } else {
      range = [haystack rangeOfString:pattern options:options range:searchRange];
    }

  } else {
    // backwards
    searchRange.location = 0;
    if (inclusive)
      searchRange.length = NSMaxRange(startRange);
    else
      searchRange.length = startRange.location;

    if ((flags & SearchRegexMask) == SearchRegexEnabled) {
      NSArray *matchlist = [lastRegex findAllInString:haystack range:searchRange];
      if ([matchlist count])
        range = [[matchlist objectAtIndex:[matchlist count] - 1] range];
      else
        range.length = 0;
    } else {
      options |= NSBackwardsSearch;
      range = [haystack rangeOfString:pattern options:options range:searchRange];
    }
  }

  if (range.length) {
    // match found
    [display setSelectedRange:range];
    [display scrollRangeToVisible:range];
    [self updateStatus:nil];
  } else {
    // no match found
    NSBeep();
    [status setStringValue:@"Pattern not found."];
  }
}

@end
