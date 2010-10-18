//
//  main.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 12/15/07.
//  Copyright Savory Software, LLC 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/foundation.h>
#import <SecurityFoundation/SFAuthorization.h>
#import <Security/AuthorizationTags.h>

#import "Globals.h"

bool amIWorthy(void);
void authMe(char * FullPathToMe);

int main(int argc, char *argv[])
{
    if(MEMORY_GOD_MODE) {
		int uid = getuid();
		if (amIWorthy() || uid == 0) {
            printf("It's go time.\n"); // signal back to close caller
            fflush(stdout);
            // WHOA! PG works with Xcode's console in 10.5.6!
#ifndef PGLOGGING
            fclose(stderr); // to shut up the noisy NSLog
#endif
        } else {
            authMe(argv[0]);
            return 0; 
        }
    }
    
    return NSApplicationMain(argc,  (const char **) argv);
}

bool amIWorthy(void)
{
	// running as root?
	AuthorizationRef myAuthRef;
	OSStatus stat = AuthorizationCopyPrivilegedReference(&myAuthRef, kAuthorizationFlagDefaults);
    BOOL success = (stat == errAuthorizationSuccess);

	return success;
}

void authMe(char * FullPathToMe)
{
	// get authorization as root
	OSStatus myStatus;
	
	// set up Authorization Item
	AuthorizationItem myItems[1];
	myItems[0].name = kAuthorizationRightExecute;
	myItems[0].valueLength = 0;
	myItems[0].value = NULL;
	myItems[0].flags = 0;
	
	// Set up Authorization Rights
	AuthorizationRights myRights;
	myRights.count = sizeof (myItems) / sizeof (myItems[0]);
	myRights.items = myItems;
	
	// set up Authorization Flags
	AuthorizationFlags myFlags;
	myFlags =
		kAuthorizationFlagDefaults |
		kAuthorizationFlagInteractionAllowed |
		kAuthorizationFlagExtendRights;
	
	// Create an Authorization Ref using Objects above. NOTE: Login bod comes up with this call.
	AuthorizationRef myAuthorizationRef;
	myStatus = AuthorizationCreate (&myRights, kAuthorizationEmptyEnvironment, myFlags, &myAuthorizationRef);
	
	if (myStatus == errAuthorizationSuccess)
	{
		// prepare communication path - used to signal that process is loaded
		FILE *myCommunicationsPipe = NULL;
		char myReadBuffer[256];
        
		// run this app in GOD mode by passing authorization ref and comm pipe (asynchoronous call to external application)
		myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, FullPathToMe, kAuthorizationFlagDefaults, nil, &myCommunicationsPipe);
        
		// external app is running asynchronously - it will send to stdout when loaded
		if (myStatus == errAuthorizationSuccess)
		{
            
#ifdef PGLOGGING
            for(;;) { 
                int bytesRead = read(fileno(myCommunicationsPipe), myReadBuffer, sizeof(myReadBuffer)); 
                if (bytesRead < 1) { // < 1
                    break; 
                }
                write(fileno(stdout), myReadBuffer, bytesRead); 
                fflush(stdout);
            }
#else
			read(fileno(myCommunicationsPipe), myReadBuffer, sizeof(myReadBuffer));
#endif
            fclose(myCommunicationsPipe);
		}
		
		// release authorization reference
		myStatus = AuthorizationFree (myAuthorizationRef, kAuthorizationFlagDestroyRights);
	}
}

