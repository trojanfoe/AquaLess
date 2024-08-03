//
// PagerDocument.h
//
// AquaLess - a less-compatible text pager for Mac OS X
// Copyright (c) 2003-2006 Christoph Pfisterer
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

@class InputParser;


@interface PagerDocument : NSDocument
{
  IBOutlet id display;
  IBOutlet id scroller;

  BOOL isFile;
  NSString *givenTitle;
  NSFileHandle *fileHandle;
  unsigned long long lastSize;
  NSTimer *tailWatchTimer;

  NSMutableData *data;
  NSTextStorage *storage;
  NSArray *applicableFormats;
  Class currentFormat;
  InputParser *parser;
}

// nib loading stuff

- (void)makeWindowControllers;

// file reading

- (void)didReadNextChunk:(NSNotification *)notification;
- (void)startTailWatch;
- (void)tailWatchTimeout:(NSTimer *)timer;

// data access

- (NSString *)givenTitle;
- (void)setGivenTitle:(NSString *)newTitle;

- (NSData *)data;
- (void)addData:(NSData *)data;

- (NSTextStorage *)storage;

- (NSString *)statusLine;

// parsing

+ (NSArray *)allFormats;
- (NSArray *)applicableFormats;

- (void)detectFormats;
- (Class)currentFormat;
- (void)setCurrentFormat:(Class)format;

- (void)reparse;

@end

extern NSString *StatusChangedNotification;
