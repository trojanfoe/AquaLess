//
// ToolInstaller.m
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

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#import "ToolInstaller.h"

static const char *version_id_prefix = "|aless_version_id|";
static const char version_id_terminator = '|';

static NSString *getVersion(NSString *filePath);
static int installTool(NSString *bundlePath, NSString *systemPath);


void checkAndInstallTool()
{
  // first get the path of the copy of the tool inside out bundle
  NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"aless" ofType:nil];
  if (bundlePath == nil) {
    NSRunCriticalAlertPanel(@"Application Damaged",
                            @"The AquaLess application was damaged. Try re-installing it to fix this.",
                            @"OK", nil, nil);
    return;
  }

  // the installation location
  NSString *systemPath = @"/usr/local/bin/aless";

  // check the installation
  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:systemPath]) {
    // not installed

    // ask the user
    int response =
    NSRunAlertPanel(@"Command Line Tool Installation",
                    @"To use AquaLess properly, the \"aless\" command line tool must be installed in /usr/local/bin. The process is automatic, but may require an administrator password.",
                    @"Install", @"Cancel", nil);
    if (response != NSAlertDefaultReturn)
      return;

    // do the installation
    if (installTool(bundlePath, systemPath) == 0) {
      NSRunInformationalAlertPanel(@"Installation Successful",
                                   @"The \"aless\" command line tool is now installed.",
                                   @"OK", nil, nil);
    } else {
      NSRunAlertPanel(@"Installation Failed",
                      @"Installation of the command line tool failed. To try again, quit and re-launch AquaLess.",
                      @"OK", nil, nil);
    }

  } else {
    NSString *bundleVersion = getVersion(bundlePath);
    NSString *systemVersion = getVersion(systemPath);
    if (![systemVersion isEqualToString:bundleVersion]) {
      // other version

      // ask the user
      int response =
        NSRunAlertPanel(@"Command Line Tool Update",
                        @"The copy of the \"aless\" command line tool on your system is outdated. It is strongly recommended to update it. The process is automatic, but may require an administrator password.",
                        @"Update", @"Cancel", nil);
      if (response != NSAlertDefaultReturn)
        return;

      // do the installation
      if (installTool(bundlePath, systemPath) != 0) {
        NSRunAlertPanel(@"Updating Failed",
                        @"Updating the command line tool failed. To try again, quit and re-launch AquaLess.",
                        @"OK", nil, nil);
      }
    }

  }
}


static NSString *getVersion(NSString *filePath)
{
  NSString *version = @"";
  NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];

  const char *data = [fileData bytes];
  unsigned length = [fileData length];
  const char *end = data + length;
  const char *p = data;
  while (p < end) {
    p = memchr(p, version_id_prefix[0], end - p);
    if (p == NULL)
      break;
    if (memcmp(p, version_id_prefix, strlen(version_id_prefix)) == 0) {
      const char *version_id_start = p + strlen(version_id_prefix);
      if (version_id_start < end) {
        const char *q = memchr(version_id_start, version_id_terminator, end - version_id_start);
        if (q != NULL && q < end) {
          version = [NSString stringWithCString:version_id_start length:(q - version_id_start)];
          break;
        }
      }
    }
    p++;
  }

  [fileData release];
    return version;
}

static int installTool(NSString *bundlePath, NSString *systemPath)
{
  OSStatus myStatus;

  // create authorization session
  AuthorizationFlags myFlags = kAuthorizationFlagDefaults;
  AuthorizationRef myAuthorizationRef;
  myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
                                 myFlags, &myAuthorizationRef);
  if (myStatus != errAuthorizationSuccess)
    return myStatus;


  do {

    // add the execute right
    {
      AuthorizationItem myItems = { kAuthorizationRightExecute, 0, NULL, 0 };
      AuthorizationRights myRights = { 1, &myItems };
      myFlags = kAuthorizationFlagDefaults |
        kAuthorizationFlagInteractionAllowed |
        kAuthorizationFlagPreAuthorize |
        kAuthorizationFlagExtendRights;
      myStatus = AuthorizationCopyRights(myAuthorizationRef,
                                         &myRights, NULL, myFlags, NULL );
    }
    if (myStatus != errAuthorizationSuccess)
      break;

    // call /usr/bin/install to do the dirty work
    {
      const char *myToolPath = "/usr/bin/install";
      const char *myArguments[] = { "-o", "root", "-g", "wheel", "-m", "755", "-c", "-S",
        [bundlePath UTF8String], [systemPath UTF8String], NULL };

      myFlags = kAuthorizationFlagDefaults;
      myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef,
                                                    myToolPath, myFlags,
                                                    (char **)myArguments,
                                                    NULL);
      // NOTE: The cast of myArguments avoids a compiler warning only.
      //  The function actually expects a "const * char *", but the Obj-C
      //  compiler somehow doesn't know about that...
    }
  } while (0);

  AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDefaults);

  return myStatus;
}
