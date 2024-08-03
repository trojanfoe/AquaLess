//
// PagerDocument.m
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

#import "PagerDocument.h"
#import "PagerWindowController.h"

#import "SmartTextInputParser.h"
#import "RawTextInputParser.h"
#import "HexdumpInputParser.h"

#include <sys/types.h>
#include <sys/stat.h>

NSString *StatusChangedNotification = @"Pager Status Changed Notification";


#define BUFSIZE (8192)
// identical to the one of aless, lower than CHUNKSIZE of InputParser.m


@implementation PagerDocument

- (id)init
{
  self = [super init];
  if (self) {

    isFile = NO;
    givenTitle = nil;
    fileHandle = nil;
    tailWatchTimer = nil;

    data = [[NSMutableData alloc] init];
    if (data == nil) {
      [self release];
      return nil;
    }

    storage = [[NSTextStorage alloc] init];
    if (storage == nil) {
      [data release];
      [self release];
      return nil;
    }

    applicableFormats = nil;
    currentFormat = nil;
    parser = nil;

  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [givenTitle release];
  [fileHandle release];
  [tailWatchTimer release];
  [storage release];
  [data release];
  [applicableFormats release];
  [parser release];

  [super dealloc];
}

- (void)close
{
  // make sure the we're ready to be released - tailWatchTimer may hold a reference on us
  if (tailWatchTimer) {
    [tailWatchTimer invalidate];
    [tailWatchTimer autorelease];
    tailWatchTimer = nil;
  }

  [super close];
}

// window title

- (NSString *)displayName
{
  if (isFile)
    return [super displayName];
  else if (givenTitle)
    return givenTitle;
  else
    return @"Standard Input";
}

// nib loading stuff

- (void)makeWindowControllers
{
  PagerWindowController *controller = [[PagerWindowController allocWithZone:
    [self zone]] init];
  [self addWindowController:controller];
  [controller release];
}

// file read and write

- (NSData *)dataRepresentationOfType:(NSString *)aType
{
  // saving is not implemented
  return nil;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
  isFile = YES;

  // start over completely
  if (fileHandle != nil)
    [fileHandle release];
  [[storage mutableString] setString:@""];
  [data setLength:0];
  // even forget detected formats, leading to parser re-creation
  if (applicableFormats != nil) {
    [applicableFormats release];
    applicableFormats = nil;
    currentFormat = nil;
  }

  // start reading the file
  fileHandle = [[NSFileHandle fileHandleForReadingAtPath:fileName] retain];
  if (fileHandle == nil) {
    // TODO: message the user here?
    return NO;
  }
  NSData *chunk = [fileHandle readDataOfLength:BUFSIZE];
  [self addData:chunk];

  // arrange for other data to be read asynchronously
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didReadNextChunk:)
                                               name:NSFileHandleReadCompletionNotification
                                             object:fileHandle];
  [fileHandle readInBackgroundAndNotify];

  return YES;
}

- (void)didReadNextChunk:(NSNotification *)notification
{
  if ([notification object] != fileHandle)
    return;

  NSData *chunk = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([chunk length] == 0) {
    [self startTailWatch];
  } else {
    [self addData:chunk];
    [fileHandle readInBackgroundAndNotify];
  }
}

- (void)startTailWatch
{
  struct stat sb;

  if (tailWatchTimer)
    return;  // already in tail-watch mode

  if (fstat([fileHandle fileDescriptor], &sb) == 0) {
    lastSize = sb.st_size;

    tailWatchTimer =
      [NSTimer scheduledTimerWithTimeInterval:1
                                       target:self
                                     selector:@selector(tailWatchTimeout:)
                                     userInfo:nil
                                      repeats:NO];
    [tailWatchTimer retain];
  }
}

- (void)tailWatchTimeout:(NSTimer *)timer
{
  struct stat sb;

  if (tailWatchTimer == timer) {
    [tailWatchTimer autorelease];
    tailWatchTimer = nil;
  }

  if (fstat([fileHandle fileDescriptor], &sb) == 0) {
    unsigned long long newSize = sb.st_size;

    if (newSize > lastSize) {
      // there is new data, read it, continue watching after that
      [fileHandle readInBackgroundAndNotify];
    } else if (newSize < lastSize) {
      // the file got shorter!
      // TODO: close the file and re-read it from the beginning
    } else {
      // nothing changed, try again later
      [tailWatchTimer autorelease];
      tailWatchTimer = 
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(tailWatchTimeout:)
                                       userInfo:nil
                                        repeats:NO];
      [tailWatchTimer retain];
    }
  }
}

// data access

- (NSString *)givenTitle
{
  return givenTitle;
}

- (void)setGivenTitle:(NSString *)newTitle
{
  [givenTitle autorelease];
  givenTitle = [newTitle retain];
}

- (NSData *)data
{
  return data;
}

- (NSTextStorage *)storage
{
  return storage;
}

- (void)addData:(NSData *)newData
{
  // add to storage
  [data appendData:newData];

  if (applicableFormats == nil) {
    // first chunk: detect formats, create a parser, automatically consume all present data
    [self detectFormats];
  } else if (parser != nil) {
    // following chunks: notify the parser to resume from its last checkpoint
    [parser newData];
  }
  // if applicableFormats is present, but parser is not, then no format matched

  [[NSNotificationCenter defaultCenter] postNotificationName:StatusChangedNotification
                                                      object:self];
}

- (NSString *)statusLine
{
  NSMutableString *s = [NSMutableString string];

  unsigned len = [[self data] length];
  if (len < 1000) {
    [s appendFormat:@"%u bytes", len];
  } else {
    [s appendFormat:@"%u KB (%u bytes)", (len + 511) >> 10, len];
  }

  return s;
}

// parsing

+ (NSArray *)allFormats
{
  static NSArray *formats = nil;

  if (formats == nil) {
    NSMutableArray *a = [NSMutableArray array];

    // order here determines order in the popup menu
    [a addObject:[SmartTextInputParser class]];
    [a addObject:[RawTextInputParser class]];
    [a addObject:[HexdumpInputParser class]];

    formats = [a retain];
  }

  return formats;
}

- (NSArray *)applicableFormats
{
  return applicableFormats;
}

- (void)detectFormats
{
  // get list of known formats
  NSArray *formats = [PagerDocument allFormats];

  // filter those that apply
  NSMutableArray *a = [NSMutableArray array];
  unsigned i;
  int bestPriority = -1;
  Class bestFormat = nil;
  for (i = 0; i < [formats count]; i++) {
    Class format = [formats objectAtIndex:i];
    if ([format canReadData:[self data]]) {
      [a addObject:format];
      if (bestPriority < [format priority]) {
        bestPriority = [format priority];
        bestFormat = format;
      }
    }
  }
  applicableFormats = [a retain];

  // create a parser for the best choice
  [self setCurrentFormat:bestFormat];
}

- (Class)currentFormat
{
  return currentFormat;
}

- (void)setCurrentFormat:(Class)format
{
    if (currentFormat == format)
        return;  // no change
    
    currentFormat = format;
    [self reparse];
}

- (void)reparse
{
    // kill old parser if present
    if (parser != nil) {
        [parser release];
        parser = nil;
    }
    
    // empty text storage before starting over
    [storage beginEditing];
    [[storage mutableString] setString:@""];
    [storage endEditing];
    
    // create new parser if format exists
    if (currentFormat != nil) {
        parser = [[currentFormat alloc] initWithDocument:self];
        // NOTE: the creation automatically invokes the parser on the present data
    }
    
    // update status line and format menu
    [[NSNotificationCenter defaultCenter] postNotificationName:StatusChangedNotification
                                                        object:self];
}

@end
