//
// PagerTextView.m
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

#import "PagerTextView.h"
#import "PagerWindowController.h"


@implementation PagerTextView


- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect]) {
    [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

// keyboard handling

- (void)keyDown:(NSEvent *)theEvent
{
  BOOL handled = NO;

  NSString *keys = [theEvent charactersIgnoringModifiers];
  if ([keys length] > 0) {
    int c = [keys characterAtIndex:0];

    handled = YES;
    switch (c)
    {
    case NSDownArrowFunctionKey:
    case 13:
    case 10:
    case 'e':
    case 'j':
      [self scrollLines:1];
      break;
    case NSUpArrowFunctionKey:
    case 'y':
    case 'p':
    case 'k':
      [self scrollLines:-1];
      break;
    case 32:
      if ([theEvent modifierFlags] & NSShiftKeyMask)
        [self scrollPages:-1];
      else
        [self scrollPages:1];
      break;
    case NSPageDownFunctionKey:
    case 'f':
    case 'z':
    case 'v':
      [self scrollPages:1];
      break;
    case NSPageUpFunctionKey:
    case 'b':
    case 'w':
      [self scrollPages:-1];
      break;
    case 'd':
      [self scrollPages:0.5];
      break;
    case 'u':
      [self scrollPages:-0.5];
      break;
    case NSHomeFunctionKey:
    case 'g':
    case '<':
      [self scrollPoint:NSMakePoint(0, 0)];
      break;
    case NSEndFunctionKey:
    case 'G':
    case '>':
      [self scrollPoint:NSMakePoint(0, [self bounds].size.height)];
      break;
    case 'F':
      [self startTailLock:self];
      break;
    case 'q':
      [[self window] performClose:self];
      break;
    case '/':
      if ([[[self window] delegate] respondsToSelector:@selector(showFindPanelBackwards:)])
        [[[self window] delegate] showFindPanelBackwards:NO];
      else
        handled = NO;
      break;
    case '?':
      if ([[[self window] delegate] respondsToSelector:@selector(showFindPanelBackwards:)])
        [[[self window] delegate] showFindPanelBackwards:YES];
      else
        handled = NO;
      break;
    case 'n':
      if ([[[self window] delegate] respondsToSelector:@selector(findAgainSameDirection:)])
        [[[self window] delegate] findAgainSameDirection:self];
      else
        handled = NO;
      break;
    case 'N':
      if ([[[self window] delegate] respondsToSelector:@selector(findAgainOtherDirection:)])
        [[[self window] delegate] findAgainOtherDirection:self];
      else
        handled = NO;
      break;
    default:
      handled = NO;
      break;
    }
  }

  if (!handled)
    [super keyDown:theEvent];
}

// relative scrolling

- (void)scrollBy:(NSPoint)offset
{
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView == nil)
    return;
  NSClipView *clipView = [scrollView contentView];

  NSPoint scrollTo = [clipView bounds].origin;
  scrollTo.x += offset.x;
  if ([clipView isFlipped])
    scrollTo.y += offset.y;
  else
    scrollTo.y -= offset.y;
  scrollTo = [clipView constrainScrollPoint:scrollTo];
  [clipView scrollToPoint:scrollTo];
  [scrollView reflectScrolledClipView:clipView];
}
/* from iTerm:

 NSRect scrollRect;

 scrollRect= [self visibleRect];
 scrollRect.origin.y-=[[self enclosingScrollView] verticalLineScroll];
 //NSLog(@"%f/%f",[[self enclosingScrollView] verticalLineScroll],[[self enclosingScrollView] verticalPageScroll]);
 [self scrollRectToVisible: scrollRect];
*/

- (void)scrollLines:(int)lines
{
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView == nil)
    return;

  [self scrollBy:NSMakePoint(0, lines * [scrollView verticalLineScroll])];
}

- (void)scrollPages:(float)pages
{
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView == nil)
    return;
  NSClipView *clipView = [scrollView contentView];

  int lineHeight = [scrollView verticalLineScroll];
  int linesPerPage = [clipView bounds].size.height / lineHeight - 1;
  [self scrollBy:NSMakePoint(0, floor(pages * linesPerPage + 0.5) * lineHeight)];
}

// tail lock

- (IBAction)startTailLock:(id)sender
{
  // scroll down all the way
  [self scrollPoint:NSMakePoint(0, [self bounds].size.height)];

  // remember this for future text changes
  tailLock = YES;

  // remember scroll position to detect changes that end tail-lock mode
  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView != nil) {
    NSClipView *clipView = [scrollView contentView];
    tailLastPosition = [clipView bounds].origin.y;
    //NSLog(@"first remembered position: %.0f", tailLastPosition);
  } else {
    //NSLog(@"Can't get scroll view");
    tailLock = NO;
  }
}

- (void)textAppended:(NSNotification *)notification;
{
  if (!tailLock) {
    //NSLog(@"textAppended: tail lock not engaged");
    return;
  }

  NSScrollView *scrollView = [self enclosingScrollView];
  if (scrollView != nil) {
    NSClipView *clipView = [scrollView contentView];
    float currentPosition = [clipView bounds].origin.y;
    if (currentPosition != tailLastPosition) {
      //NSLog(@"mismatch: remembered %.0f, now have %.0f", tailLastPosition, currentPosition);
      tailLock = NO;
    } else {
      [self scrollPoint:NSMakePoint(0, [self bounds].size.height)];
      tailLastPosition = [clipView bounds].origin.y;
      //NSLog(@"new remembered position: %.0f", tailLastPosition);
    }
  } else {
    //NSLog(@"Can't get scroll view");
    tailLock = NO;
  }
}

// determine the visible range of characters

- (NSRange)visibleRange
{
  NSRange visibleGlyphRange, visibleCharRange;
  NSLayoutManager *layoutManager = [self layoutManager];
  NSTextContainer *textContainer = [self textContainer];
  NSPoint containerOrigin = [self textContainerOrigin];
  NSRect visibleRect = [self visibleRect];

  // convert from view coordinates to container coordinates
  visibleRect.origin.x -= containerOrigin.x;
  visibleRect.origin.y -= containerOrigin.y;
  // don't count barely visible lines
  visibleRect.origin.y += 4;
  visibleRect.size.height -= 8;

  visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:textContainer];
  visibleCharRange = [layoutManager characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];

  return visibleCharRange;
}

@end
