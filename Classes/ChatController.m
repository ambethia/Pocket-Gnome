//
//  ChatController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 4/28/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

#import "ChatController.h"
#import "Controller.h"

@interface ChatController (Internal)
- (CGEventSourceRef)source;
BOOL Ascii2Virtual(char pcar, BOOL *pshift, BOOL *palt, char *pkeycode);
@end

@implementation ChatController



- (id) init
{
    self = [super init];
    if (self != nil) {
        theSource = NULL;
    }
    return self;
}

- (CGEventSourceRef)source {
    if(theSource == NULL) {
        theSource = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);  
        if(theSource) {
            CGEventSourceSetKeyboardType(theSource, LMGetKbdType());
            CGEventSourceSetLocalEventsSuppressionInterval(theSource, 0.0);
            CGEventSourceSetLocalEventsFilterDuringSuppressionState(theSource, kCGEventFilterMaskPermitLocalMouseEvents, kCGEventSuppressionStateSuppressionInterval);
        }
    }
    return theSource;
}

- (void)tab {
    [self sendKeySequence: [NSString stringWithFormat: @"%c", '\t']];
}

- (void)enter {
    [self sendKeySequence: [NSString stringWithFormat: @"%c", '\n']];
}

- (void)jump {
    [self sendKeySequence: @" "];
}

BOOL Ascii2Virtual(char pcar, BOOL *pshift, BOOL *palt, char *pkeycode) 
{
    KeyboardLayoutRef keyboard;
    const void *keyboardData; // keyboard layout data
    UInt16 nbblocs;
    char *modblocs, *blocs, *deadkeys;
    int ix, ifin, numbloc, keycode;
    
    BOOL shift, alt;
    
    // récupération du clavier courant
    // get the current keyboard
    if(KLGetCurrentKeyboardLayout(&keyboard)) return NO;
    
    // récupération de la description (keyboard layout) du clavier courant
    // get the description of the current keyboard layout
    if(KLGetKeyboardLayoutProperty(keyboard, kKLKCHRData, &keyboardData)) return NO;
    
    // récupération du pointeur de début des numéros de blocs pour chaque combinaison de modifiers
    // get pointer early numbers of blocks for each combination of modifiers
    modblocs = ((char *)keyboardData) + 2;
    
    // récupération de nombre de blocs keycode->ascii
    // get number of blocks keycode->ascii
    nbblocs = *((UInt16 *)(keyboardData + 258));
    
    // récupération du pointeur de début des blocs keycode->ascii
    // get pointer early blocks keycode-> ascii
    blocs = ((char *)keyboardData) + 260;
    
    // on détermine la taille de toutes les tables keycode->ascii à scanner
    // determining the size of all tables keycode-> ascii a scanner
    ifin = nbblocs*128;
    
    // on détermine le pointeur de début de la tables des dead keys
    // determining pointer early in the tables of dead keys
    deadkeys = blocs+ifin;
    
    // maintenant on parcourt les blocs keycode->ascii pour retrouver le car ascii
    // Now it runs blocks keycode-> ascii to find the car ascii
    for (ix=0; ix<ifin; ix++)
    {
        if (blocs[ix]==pcar)
        {
            // car ascii trouvé : il faut déterminer dans quel bloc (numéro du bloc) il se trouve
            // found ascii value: now we must determine which block it is
            keycode = ix & 0x7f; // 0111 1111 mask
            numbloc = ix >> 7;
            // log(LOG_DEV, @"Found ascii at %d; block = %d, keycode = %d", ix, numbloc, keycode);
            break;
        }
    }
    
    // car non trouvé : on termine (avec erreur)
    // not found: bail out (error)
    if (ix >= ifin) return NO;
    
    // à partir du numéro de bloc, il faut retrouver la combinaison de modifiers utilisant ce bloc
    // from block number, we must find the combination of modifiers using this block
    for (ix=0; ix<15; ix++)
    {
        // on ne traite pas si les modifiers ne sont pas "majuscule" et "option"
        // it does not address whether the modifiers are not "capital" and "option"
        if (ix&1 || ix&4) continue;
        
        // combinaison de modifiers trouvée pour le bloc
        // Combining modifiers found for the block
        if (modblocs[ix]==numbloc)
        {
            shift = (ix&2) ? YES : NO;
            alt   = (ix&8) ? YES : NO;
            break;         
        }
    }
    
    // combinaison modifiers non trouvé : on termine (avec erreur)
    // combination modifiers not found: bail
    if (ix>=15) return NO;
    
    // mise à jour des paramètres
    // save our parameters
    *pkeycode=keycode;
    *pshift=shift;
    *palt=alt;
    
    return YES;
}


- (int)keyCodeForCharacter: (NSString*)character {
    if(![character length]) return -1;
    
    char code;
    BOOL shift, alt;
    if(Ascii2Virtual( (char)[character characterAtIndex: 0], &shift, &alt, &code)) {
        return code;
    }
    return -1;
}

- (void)sendKeySequence:(NSString*)keySequence {
	
	ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    
    if(wowPSN.lowLongOfPSN == kNoProcess && wowPSN.highLongOfPSN == kNoProcess) {
        return;
    }
	
	log(LOG_DEV, @"[Chat] Sending '%@'", keySequence);
    
    // get our C string from the NSString
    int strLen = [keySequence length];
    unichar buffer[strLen+1];
    [keySequence getCharacters: buffer];
    log(LOG_DEV, @"Sequence \"%@\" has %d characters.", keySequence, strLen);
    
    // create the event source
    CGEventRef tempEvent = CGEventCreate(NULL);
    if(tempEvent) CFRelease(tempEvent);
    CGEventSourceRef source = [self source];
    if(source) {
        
        // start looping over the characters
        unsigned i;
        char keyCode;
        BOOL shift, option;
        
        for(i=0; i<strLen && buffer[i]!=0; i++) {
            keyCode = -1;
            shift = option = NO;
            if(!Ascii2Virtual( (char)buffer[i], &shift, &option, &keyCode)) {
                // special case support
                if(buffer[i] == '\n')   keyCode = 36;
                if(buffer[i] == '\t')   keyCode = 48;
            }
            
            // if we have a valid keycode, hit it
            if(keyCode >= 0) {
                log(LOG_DEV, @"%d (shift: %d)", keyCode, shift);
                
                // create key events
                CGEventRef keyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)keyCode, TRUE);
                CGEventRef keyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)keyCode, FALSE);
                
                // setup flags
                int flags = 0;
                flags = flags | (option ? kCGEventFlagMaskAlternate : 0);
                flags = flags | (shift  ? kCGEventFlagMaskShift     : 0);
                
                // set flags
                CGEventSetFlags(keyDn, flags);
                CGEventSetFlags(keyUp, flags);
                
                // hit any specified modifier keys
                if( option )	{
                    CGEventRef altKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Option, TRUE);
                    CGEventPostToPSN(&wowPSN, altKeyDn);
                    if(altKeyDn) CFRelease(altKeyDn);
                    usleep(10000);
                }
                if( shift ) {
                    CGEventRef sftKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Shift, TRUE);
                    CGEventPostToPSN(&wowPSN, sftKeyDn);
                    if(sftKeyDn) CFRelease(sftKeyDn);
                    usleep(10000);
                }
                
                // delay before we hit return
                if(keyCode == kVK_Return) {
                    usleep(100000);
                }
                
                // post the key
                CGEventPostToPSN(&wowPSN, keyDn);
                usleep(30000);
                CGEventPostToPSN(&wowPSN, keyUp);
                
                // delay if this was the first character typed
                if(i == 0) {
                    usleep(100000);
                }
                
                // undo modifiers keys
                if( shift) {
                    CGEventRef sftKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Shift, FALSE);
                    CGEventPostToPSN(&wowPSN, sftKeyUp);
                    if(sftKeyUp) CFRelease(sftKeyUp);
                    usleep(10000);
                }
                if( option ) {
                    CGEventRef altKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Option, FALSE);
                    CGEventPostToPSN(&wowPSN, altKeyUp);
                    if(altKeyUp) CFRelease(altKeyUp);
                    usleep(10000);
                }
                
                // release keys
                if(keyDn) CFRelease(keyDn);
                if(keyUp) CFRelease(keyUp);
            }
        }
        
        // release source
        //CFRelease(source);
    }

    return;
}

- (void)pressHotkey: (int)hotkey withModifier: (unsigned int)modifier {
    if((hotkey < 0) || (hotkey > 128)) return;
    //if(modifier < 0 || modifier > 3) return;
	
    log(LOG_DEV, @"[Chat] Pressing %d with flags 0x%X", hotkey, modifier);
    
    unsigned int flags = modifier;
    ProcessSerialNumber wowPSN = [controller getWoWProcessSerialNumber];
    if(wowPSN.lowLongOfPSN == kNoProcess && wowPSN.highLongOfPSN == kNoProcess) return;
    
    CGEventRef tempEvent = CGEventCreate(NULL);
    if(tempEvent) CFRelease(tempEvent);
    
    // create the key down.up
    CGEventRef keyDn = NULL, keyUp = NULL;
    
    // create our source
    CGEventSourceRef source = [self source];
    if(source) {
        
        // KLGetCurrentKeyboardLayout?
        // TISCopyCurrentKeyboardLayoutInputSource?
        
        keyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)hotkey, TRUE);
        keyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)hotkey, FALSE);
        
        // set flags for the event (does this even matter? No.)
        CGEventSetFlags(keyDn, modifier);
        CGEventSetFlags(keyUp, modifier);
        
        // hit any specified modifier keys
        if( flags & NSAlternateKeyMask)	{
            CGEventRef altKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Option, TRUE);
            if(altKeyDn) {
                CGEventPostToPSN(&wowPSN, altKeyDn);
                CFRelease(altKeyDn);
                usleep(10000);
            }
        }
        if( flags & NSShiftKeyMask) {
            CGEventRef sftKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Shift, TRUE);
            if(sftKeyDn) {
                CGEventPostToPSN(&wowPSN, sftKeyDn);
                CFRelease(sftKeyDn);
                usleep(10000);
            }
        }
        if( flags & NSControlKeyMask) {
            CGEventRef ctlKeyDn = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Control, TRUE);
            if(ctlKeyDn) {
                CGEventPostToPSN(&wowPSN, ctlKeyDn);
                CFRelease(ctlKeyDn);
                usleep(10000);
            }
        }
        
        // post the actual event
        CGEventPostToPSN(&wowPSN, keyDn);
        usleep(30000);
        CGEventPostToPSN(&wowPSN, keyUp);
        usleep(10000);
        
        // undo the modifier keys
        if( flags & NSControlKeyMask) {
            CGEventRef ctlKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Control, FALSE);
            if(ctlKeyUp) {
                CGEventPostToPSN(&wowPSN, ctlKeyUp);
                CFRelease(ctlKeyUp);
                usleep(10000);
            }
        }
        if( flags & NSShiftKeyMask) {
            CGEventRef sftKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Shift, false);
            if(sftKeyUp) {
                CGEventPostToPSN(&wowPSN, sftKeyUp);
                CFRelease(sftKeyUp);
                usleep(10000);
            }
        }
        if( flags & NSAlternateKeyMask) {
            CGEventRef altKeyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)kVK_Option, FALSE);
            if(altKeyUp) {
                CGEventPostToPSN(&wowPSN, altKeyUp);
                CFRelease(altKeyUp);
                usleep(10000);
            }
        }
        
        if(keyDn)  CFRelease(keyDn);
        if(keyUp)  CFRelease(keyUp);
        // CFRelease(source);
    } else {
        log(LOG_GENERAL, @"invalid source with hotkey %d", hotkey);
    }
}


@end
