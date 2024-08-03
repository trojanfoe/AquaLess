//
// MyDocumentController.m
//
// AquaLess - a less-compatible text pager for Mac OS X
// Copyright (c) 2003-2008 Christoph Pfisterer
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

#import "MyDocumentController.h"
#import "PagerDocument.h"
#import "ReadmeWindowController.h"
#import "ToolInstaller.h"
#import "FontDisplayNameTransformer.h"
#import "FontHelper.h"


@implementation MyDocumentController

+ (void)initialize
{
    // register value transformers
    id transformer = [[[FontDisplayNameTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:transformer forName:@"FontDisplayNameTransformer"];

    // register default preference values
    NSColor *normalTextColor = [NSColor blackColor];
    NSColor *boldTextColor = [NSColor blueColor];
    NSFont *normalTextFont = [[NSFontManager sharedFontManager] fontWithFamily:@"Monaco"
                                                                        traits:NSUnboldFontMask|NSUnitalicFontMask
                                                                        weight:5
                                                                          size:10];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSArchiver archivedDataWithRootObject:normalTextColor], @"normalTextColor",
        [NSArchiver archivedDataWithRootObject:boldTextColor], @"boldTextColor",
        [NSArchiver archivedDataWithRootObject:normalTextFont], @"normalTextFont",
        nil, nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dict];

    [[NSUserDefaultsController sharedUserDefaultsController] setAppliesImmediately:NO];
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
        nextPipeId = 0;
        pipes = [[NSMutableDictionary dictionary] retain];
        readmeWindows = [[NSMutableDictionary dictionary] retain];
        
        // get the actual preferences value for the font
	normalTextFont = [[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"normalTextFont"]] retain];
        
    }
    
    return self;
}

- (void)dealloc
{
    [pipes release];
    [readmeWindows release];
    [normalTextFont release];
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // register server for the command line tool
    NSConnection *conn = [NSConnection defaultConnection];
    [conn setRootObject:self];
    if ([conn registerName:@"AquaLess3"] == NO) {
        NSRunAlertPanel(@"Server Registration Failed",
                        @"The AquaLess application failed to register its communication port with the system. The command line tool will not be able to contact the application.",
                        @"OK", nil, nil);
    }
    
    // check for installation of command line tool
    checkAndInstallTool();
}

- (void)openFileWithPath:(NSString *)filePath
{
    // bring us to the front
    [NSApp activateIgnoringOtherApps:YES];
    
    // open the file
    [self openDocumentWithContentsOfFile:filePath display:YES];
}

- (int)openPipe
{
    // bring us to the front
    [NSApp activateIgnoringOtherApps:YES];
    
    // make new document without file association
    PagerDocument *pipeDoc = [self openUntitledDocumentOfType:@"Text File" display:YES];
    if (pipeDoc == nil)
        return -1;
    
    // register an id and return it
    int pipeId = nextPipeId++;
    [pipes setObject:pipeDoc forKey:[NSNumber numberWithInt:pipeId]];
    return pipeId;
}

- (int)openPipeWithTitle:(NSString *)title
{
    // bring us to the front
    [NSApp activateIgnoringOtherApps:YES];
    
    // make new document without file association
    PagerDocument *pipeDoc = [self openUntitledDocumentOfType:@"Text File" display:NO];
    if (pipeDoc == nil)
        return -1;
    [pipeDoc setGivenTitle:title];
    [pipeDoc showWindows];
    
    // register an id and return it
    int pipeId = nextPipeId++;
    [pipes setObject:pipeDoc forKey:[NSNumber numberWithInt:pipeId]];
    return pipeId;
}

- (void)addData:(NSData *)data toPipe:(int)pipeId
{
    // find the document by id
    PagerDocument *pipeDoc = [pipes objectForKey:[NSNumber numberWithInt:pipeId]];
    if (pipeDoc == nil)
        return;
    
    // hand the data on
    [pipeDoc addData:data];
}

- (void)removeDocument:(NSDocument *)document
{
    // remove from pipes dict
    [pipes removeObjectsForKeys:[pipes allKeysForObject:document]];
    
    // call through
    [super removeDocument:document];
}

- (IBAction)newShell:(id)sender
{
    static NSAppleScript *terminalScript = nil;
    
    if (terminalScript == nil) {
        NSString *source = @"tell application \"Terminal\"\n  activate\n  do script \"\"\nend tell";
        terminalScript = [[NSAppleScript alloc] initWithSource:source];
    }
    
    NSDictionary *errorInfo;
    NSAppleEventDescriptor *result = [terminalScript executeAndReturnError:&errorInfo];
    
    if (result == nil) {
        NSRunAlertPanel(@"Communication Failed",
                        @"AppleScript communication with the Terminal application failed.",
                        @"OK", nil, nil);
    }
}

- (void)registerReadmeWindow:(NSString *)readmeName
              withController:(ReadmeWindowController *)controller
{
    [readmeWindows setObject:controller forKey:readmeName];
}

- (void)unregisterReadmeWindow:(NSString *)readmeName
{
    [readmeWindows removeObjectForKey:readmeName];
}

- (IBAction)showReadme:(id)sender
{
    [self openReadmeWindow:@"ReadMe"];
}

- (IBAction)showLicense:(id)sender
{
    [self openReadmeWindow:@"License"];
}

- (void)openReadmeWindow:(NSString *)readmeName
{
    ReadmeWindowController *wc = [readmeWindows objectForKey:readmeName];
    if (wc == nil)
        wc = [[[ReadmeWindowController alloc] initWithReadmeName:readmeName controller:self] autorelease];
    [[wc window] makeKeyAndOrderFront:nil];
}

- (IBAction)setFontPressed:(id)sender
{
    // disabled since it doesn't work as advertised:
    //[[NSFontManager sharedFontManager] setSelectedFont:normalTextFont isMultiple:NO];
    // set up the font panel directly instead:
    [[NSFontPanel sharedFontPanel] setPanelFont:normalTextFont isMultiple:NO];
    
    // show the font panel
    [[NSFontPanel sharedFontPanel] makeKeyAndOrderFront:self];
}

- (void)changeFont:(id)sender
{
    NSFont *oldFont = normalTextFont;
    NSFont *newFont = [sender convertFont:oldFont];
    
    [normalTextFont autorelease];
    normalTextFont = [newFont retain];
    
    [[[NSUserDefaultsController sharedUserDefaultsController] values]
      setValue:[NSArchiver archivedDataWithRootObject:normalTextFont]
        forKey:@"normalTextFont"];
}

- (IBAction)applyPrefs:(id)sender
{
    //NSFont *testFont;
    //testFont = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"normalTextFont"]];
    //NSLog(@"testFont after save: %@, %.1f", [testFont displayName], [testFont pointSize]);
    
    // save the new values
    [[NSUserDefaultsController sharedUserDefaultsController] save:sender];
    
    // MAJOR WORKAROUND: Apparently NSUserDefaultsController doesn't write the values through to
    //  the NSUserDefaults object immediately. It does write them through later on, though. But to
    //  change all open windows, we need the new values in NSUserDefaults NOW, so we have to do that
    //  manually. This is a major PITA.
    NSEnumerator *enumerator = [[[NSUserDefaultsController sharedUserDefaultsController] initialValues] keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject])) {
        [[NSUserDefaults standardUserDefaults] setObject:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:key]
                                                  forKey:key];
    }
    
    //testFont = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"normalTextFont"]];
    //NSLog(@"testFont after save: %@, %.1f", [testFont displayName], [testFont pointSize]);
    
    // rebuild cached objects
    reinitFonts();
    
    // notify open windows
    enumerator = [[self documents] objectEnumerator];
    PagerDocument *doc;
    while ((doc = [enumerator nextObject])) {
        [doc reparse];
        // TODO: also notify windows of the new size unit
    }
}

@end
