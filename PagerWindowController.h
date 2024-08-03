//
// PagerWindowController.h
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

@class FindPanelController;
@class AGRegex;


#define SearchDirectionMask 0x0003
#define SearchDirectionForwards 0x0000
#define SearchDirectionBackwards 0x0001
#define SearchDirectionSame 0x0002
#define SearchDirectionOther 0x0003

#define SearchCaseMask 0x0004
#define SearchCaseSensitive 0x0000
#define SearchCaseInsensitive 0x0004

#define SearchRegexMask 0x0008
#define SearchRegexDisabled 0x0000
#define SearchRegexEnabled 0x0008


@interface PagerWindowController : NSWindowController
{
  IBOutlet id display;
  IBOutlet id scroller;
  IBOutlet id status;
  IBOutlet id formatPopup;

  FindPanelController *findPanel;

  NSString *lastPattern;
  AGRegex *lastRegex;
  int lastFlags;
}

- (NSTextStorage *)storage;

- (void)updateStatus:(NSNotification *)notification;

- (IBAction)changeFormat:(id)sender;

- (FindPanelController *)findPanel;

- (IBAction)showFindPanel:(id)sender;
- (void)showFindPanelBackwards:(BOOL)back;

- (IBAction)findAgainForwards:(id)sender;
- (IBAction)findAgainBackwards:(id)sender;
- (IBAction)findAgainSameDirection:(id)sender;
- (IBAction)findAgainOtherDirection:(id)sender;

- (void)findPanelDidEndWithPattern:(NSString *)pattern flags:(int)flags;

- (void)findPatternWithFlags:(int)flags;

@end
