/*
	File:       SampleTool.c

    Contains:   Helper tool side of the example of how to use BetterAuthorizationSampleLib.

    Written by: DTS

    Copyright:  Copyright (c) 2007 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple, Inc.
                ("Apple") in consideration of your agreement to the following terms, and your
                use, installation, modification or redistribution of this Apple software
                constitutes acceptance of these terms.  If you do not agree with these terms,
                please do not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following terms, and subject
                to these terms, Apple grants you a personal, non-exclusive license, under Apple's
                copyrights in this original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or without
                modifications, in source and/or binary forms; provided that if you redistribute
                the Apple Software in its entirety and without modifications, you must retain
                this notice and the following text and disclaimers in all such redistributions of
                the Apple Software.  Neither the name, trademarks, service marks or logos of
                Apple, Inc. may be used to endorse or promote products derived from the
                Apple Software without specific prior written permission from Apple.  Except as
                expressly stated in this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any patent rights that
                may be infringed by your derivative works or by other works in which the Apple
                Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
                WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
                WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
                PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
                CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
                GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
                ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
                (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
                ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */
 

#import <mach/vm_map.h>
#import <mach/mach_traps.h>

#include <CoreServices/CoreServices.h>
#include "BetterAuthorizationSampleLib.h"
#include "ToolCommon.h"

#ifndef NDEBUG
#define NDEBUG
#endif

/////////////////////////////////////////////////////////////////
#pragma mark ***** Get Version Command

static OSStatus DoGetVersion(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kGetVersionCommand.  Returns the version number of 
    // the helper tool.
{	
	OSStatus					retval = noErr;
	CFNumberRef					value;
    static const int kCurrentVersion = kToolCurrentVersion;          // something very easy to spot
    
	asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "DoGetVersion()");
	
	// Pre-conditions
	
	assert(auth != NULL);
    // userData may be NULL
	assert(request != NULL);
	assert(response != NULL);
    // asl may be NULL
    // aslMsg may be NULL
	
    // Add them to the response.
    
	value = CFNumberCreate(NULL, kCFNumberIntType, &kCurrentVersion);
	if (value == NULL) {
		retval = coreFoundationUnknownErr;
    } else {
        CFDictionaryAddValue(response, CFSTR(kGetVersionResponse), value);
	}
	
	if (value != NULL) {
		CFRelease(value);
	}

	return retval;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Load Memory Command

static OSStatus DoLoadMemory(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kGetUIDsCommand.  Gets the process's three UIDs and 
    // adds them to the response dictionary.
{	
	//asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "DoLoadMemory()");
    
	// Pre-conditions
    if(auth == NULL || request == NULL || response == NULL)
        return kMemToolBadParameter;
    
    // CFShow(request);
    
    // load in the WoW ProcessID
    pid_t wowPID = 0;
    CFNumberRef cfPID = CFDictionaryGetValue(request, CFSTR(kWarcraftPID));
    if(!CFNumberGetValue(cfPID, kCFNumberIntType, &wowPID) || wowPID <= 0) {
        return kMemToolBadPID;
    }
    
    // load in the memory address
    unsigned int address = 0;
    CFNumberRef cfAddress = CFDictionaryGetValue(request, CFSTR(kMemoryAddress));
    if(!CFNumberGetValue(cfAddress, kCFNumberIntType, &address) || address == 0) {
        return kMemToolBadAddress;
    }
    
    // load in memory length
    vm_size_t length = 0;
    CFNumberRef cfLength = CFDictionaryGetValue(request, CFSTR(kMemoryLength));
    if(!CFNumberGetValue(cfLength, kCFNumberIntType, &length) || length == 0) {
        return kMemToolBadLength;
    }
    
    bool memSuccess = false;
    if(wowPID && address && length) {
        //asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "Reading pid %d at address 0x%X for length %d", wowPID, address, length);
        
        // create buffer for our data
        Byte buffer[length];
        
        int i;
        for(i=0; i<length; i++)
            buffer[i] = 0;
        
        // get a handle on the WoW task
        mach_port_t wowTask;
        task_for_pid(current_task(), wowPID, &wowTask);
        
        vm_size_t bytesRead = length;
        memSuccess = ((KERN_SUCCESS == vm_read_overwrite(wowTask, address, length, (vm_address_t)&buffer, &bytesRead)) && (bytesRead == length) );
        
        //(KERN_SUCCESS == vm_write(wowTask, address, (vm_offset_t)&buffer, length));
        
        if(memSuccess) {
            CFDataRef memoryContents = CFDataCreate(NULL, buffer, length);
            if(memoryContents != NULL) {
                // we got our memory! add it to the return dictionary
                CFDictionaryAddValue(response, CFSTR(kMemoryContents), memoryContents);
                CFRelease(memoryContents);
                return kMemToolNoError;
            }
        }
    } else {
        return kMemToolBadParameter;
    }

	return kMemToolUnknown;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Save Memory Command

static OSStatus DoSaveMemory(
	AuthorizationRef			auth,
    const void *                userData,
	CFDictionaryRef				request,
	CFMutableDictionaryRef      response,
    aslclient                   asl,
    aslmsg                      aslMsg
)
    // Implements the kLowNumberedPortsCommand.  Opens three low-numbered ports 
    // and adds them to the descriptor array in the response dictionary.
{	
   
	// Pre-conditions
    if(auth == NULL || request == NULL || response == NULL)
        return kMemToolBadParameter;
    
    // CFShow(request);
    
    // load in the WoW ProcessID
    pid_t wowPID = 0;
    CFNumberRef cfPID = CFDictionaryGetValue(request, CFSTR(kWarcraftPID));
    if(!CFNumberGetValue(cfPID, kCFNumberIntType, &wowPID) || wowPID <= 0) {
        return kMemToolBadPID;
    }
    
    // load in the memory address
    unsigned int address = 0;
    CFNumberRef cfAddress = CFDictionaryGetValue(request, CFSTR(kMemoryAddress));
    if(!CFNumberGetValue(cfAddress, kCFNumberIntType, &address) || address == 0) {
        return kMemToolBadAddress;
    }
    
    // load in memory length
    CFIndex length = 0;
    CFDataRef cfContents = CFDictionaryGetValue(request, CFSTR(kMemoryContents));
    if( !(length = CFDataGetLength(cfContents))) {
        return kMemToolBadContents;
    }
    
    bool memSuccess = false;
    if(wowPID && address && cfContents && length) {
        asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "Writing to pid %d at address 0x%X with data length %ld", wowPID, address, length);
        
        // put our data into a local buffer
        Byte buffer[length];
        CFDataGetBytes(cfContents, CFRangeMake(0, length), buffer);
        
        // get a handle on the WoW task
        mach_port_t wowTask;
        task_for_pid(current_task(), wowPID, &wowTask);
        
        memSuccess = (KERN_SUCCESS == vm_write(wowTask, address, (vm_offset_t)&buffer, length));
        
        if(memSuccess) {
            asl_log(asl, aslMsg, ASL_LEVEL_DEBUG, "Write success!");
            return kMemToolNoError;
        }
    } else {
        return kMemToolBadParameter;
    }

	return kMemToolUnknown;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Tool Infrastructure

/*
    IMPORTANT
    ---------
    This array must be exactly parallel to the kCommandSet array 
    in "SampleCommon.c".
*/

static const BASCommandProc kCommandProcs[] = {
    DoGetVersion,
    DoLoadMemory,
    DoSaveMemory,
    NULL
};

int main(int argc, char **argv)
{
    // Go directly into BetterAuthorizationSampleLib code.
	
    // IMPORTANT
    // BASHelperToolMain doesn't clean up after itself, so once it returns 
    // we must quit.
    
	return BASHelperToolMain(kCommandSet, kCommandProcs);
}
