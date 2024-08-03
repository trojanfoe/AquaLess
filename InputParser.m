//
// InputParser.m
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

#import "InputParser.h"
#import "PagerDocument.h"


#define CHUNKSIZE (10240)

static NSString *NextChunkNotification = @"InputParser Next Chunk Notification";

@implementation InputParser

+ (int)priority
{
  return 0;
}

+ (NSString *)name
{
  return @"-";
}

+ (BOOL)canReadData:(NSData *)partialData
{
  return NO;
}

- (id)init
{
  return [self initWithDocument:nil];
}

- (id)initWithDocument:(PagerDocument *)doc
{
  if (self = [super init]) {
    nextCheckpointOffset = lastCheckpointOffset = 0;
    nextCheckpointPosition = lastCheckpointPosition = 0;
    buffer = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parseNextChunk:)
                                                 name:NextChunkNotification
                                               object:self];

    document = doc;
    if (document != nil)
      [self newData];
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  if (buffer != nil)
    [buffer release];

  [super dealloc];
}

- (PagerDocument *)document
{
  return document;
}

- (void)setDocument:(PagerDocument *)doc
{
  document = doc;
  if (document != nil) {
    lastCheckpointOffset = 0;
    lastCheckpointPosition = 0;
    [self newData];
  }
}

- (void)newData
{
  unsigned limit = lastCheckpointOffset + CHUNKSIZE;
  [self parseWithLimit:limit];
}

- (void)parseNextChunk:(NSNotification *)notification
{
  if (nextLimit)
    [self parseWithLimit:nextLimit];
}

- (void)parseWithLimit:(unsigned)limit
{
  // get data from document
  NSData *data = [[self document] data];
  unsigned endOffset = [data length];

  // sanity checks
  if (lastCheckpointOffset >= endOffset)
    return;  // nothing to do or illegal situation
  if (limit < lastCheckpointOffset + CHUNKSIZE)
    limit = lastCheckpointOffset + CHUNKSIZE;
  // now both endOffset and limit are greater than lastCheckpointOffset

  // determine range to parse and whether to iterate
  if (endOffset > limit) {
    nextLimit = limit + CHUNKSIZE;  // important to use last limit, not last checkpoint!
    endOffset = limit;
  } else {
    nextLimit = 0;
    // endOffset is below limit, so we leave it untouched
  }

  // make sure buffer exists and is empty
  if (buffer != nil) {
    [[buffer mutableString] setString:@""];
  } else {
    buffer = [[NSMutableAttributedString alloc] init];
  }

  // run parser from last checkpoint
  [self parseData:(NSData *)data fromOffset:lastCheckpointOffset toOffset:endOffset];

  // add buffer to document's storage
  NSTextStorage *storage = [[self document] storage];
  [storage beginEditing];
  unsigned currentLength = [storage length];
  if (currentLength <= lastCheckpointPosition) {
    [storage appendAttributedString:buffer];
  } else {
    [storage replaceCharactersInRange:NSMakeRange(lastCheckpointPosition,
                                                  currentLength - lastCheckpointPosition)
                 withAttributedString:buffer];
  }
  [storage endEditing];

  // release buffer
  [buffer release];
  buffer = nil;

  // remember the checkpoint
  lastCheckpointOffset = nextCheckpointOffset;
  lastCheckpointPosition = nextCheckpointPosition;

  // resume later (at idle time)
  if (nextLimit) {
    NSNotification *note = [NSNotification notificationWithName:NextChunkNotification
                                                         object:self];
    [[NSNotificationQueue defaultQueue]
      enqueueNotification:note
             postingStyle:NSPostWhenIdle
             coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender
                 forModes:nil];
  }
}

- (void)parseData:(NSData *)data fromOffset:(unsigned)startOffset toOffset:(unsigned)endOffset
{
  // to be implemented by subclasses
}

- (void)addString:(NSString *)text withAttributes:(NSDictionary *)attr
{
  unsigned from = [buffer length];
  [[buffer mutableString] appendString:text];
  [buffer setAttributes:attr range:NSMakeRange(from, [text length])];
}

- (void)addString:(NSString *)text withAttributes:(NSDictionary *)attr settingCheckpoint:(unsigned)offset
{
  [self addString:text withAttributes:attr];
  [self setCheckpoint:offset];
}

- (void)setCheckpoint:(unsigned)offset
{
  // store info for next checkpoint (commited with endRun)
  nextCheckpointOffset = offset;
  nextCheckpointPosition = lastCheckpointPosition + [buffer length];
}

- (void)chomp
{
  // remove one trailing linebreak if present (avoiding the extra empty line)
  if (buffer != nil) {
    unsigned len = [buffer length];
    if (len > 0 && [[buffer mutableString] characterAtIndex:len-1] == '\n') {
      [[buffer mutableString] deleteCharactersInRange:NSMakeRange(len-1,1)];
    }
  }
}

@end
