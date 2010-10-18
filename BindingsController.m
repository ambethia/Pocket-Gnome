//
//  BindingsController.h
//  Pocket Gnome
//
//  Created by Josh on 1/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "BindingsController.h"

#import "Controller.h"
#import "PlayerDataController.h"
#import "ChatController.h"
#import "BotController.h"
#import "OffsetController.h"

#import "Behavior.h"

#import "MemoryAccess.h"

#import "Offsets.h"
#import <Carbon/Carbon.h>

@interface BindingsController (Internal)
- (void)getKeyBindings;
- (void)convertToAscii;
- (void)mapBindingsToKeys;
@end

@implementation BindingsController

- (id) init{
    self = [super init];
    if (self != nil) {
		
		_guid = 0x0;
		
		// required bindings
		_requiredBindings = [[NSArray arrayWithObjects: 
							  @"MULTIACTIONBAR1BUTTON1",            // lower left action bar
							  @"INTERACTMOUSEOVER",
							  @"TARGETLASTTARGET",
							  @"TURNLEFT",
							  @"TURNRIGHT",
							  @"MOVEFORWARD",
							  @"STRAFERIGHT",
							  @"STRAFELEFT",
							  nil] retain];
		
		// optional - basically back up in case any of the above are NOT bound
		_optionalBindings = [[NSArray arrayWithObjects:
							  @"ACTIONBUTTON1",
							  @"PETATTACK",
							  nil] retain];
		
		// might move this to a plist eventually once I have all of them
		_commandToAscii = [[NSDictionary dictionaryWithObjectsAndKeys:
							[NSNumber numberWithInt:kVK_F1]					,@"f1",
							[NSNumber numberWithInt:kVK_Shift]				,@"shift",
							[NSNumber numberWithInt:kVK_F2]					,@"f2",
							[NSNumber numberWithInt:kVK_Space]				,@"space",			
							[NSNumber numberWithInt:kVK_Control]			,@"ctrl",				
							[NSNumber numberWithInt:kVK_F3]					,@"f3",				
							[NSNumber numberWithInt:-1]						,@"button2",			
							[NSNumber numberWithInt:-1]						,@"insert",			
							[NSNumber numberWithInt:kVK_F4]					,@"f4",				
							[NSNumber numberWithInt:-1]						,@"mousewheeldown",	
							[NSNumber numberWithInt:kVK_F5]					,@"f5",				
							[NSNumber numberWithInt:kVK_F8]					,@"f8",				
							[NSNumber numberWithInt:kVK_ANSI_Keypad1]		,@"numpad1",			
							[NSNumber numberWithInt:kVK_F9]					,@"f9",				
							[NSNumber numberWithInt:kVK_ANSI_Keypad4]		,@"numpad4",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad7]		,@"numpad7",			
							[NSNumber numberWithInt:kVK_F7]					,@"f7",				
							[NSNumber numberWithInt:kVK_Option]				,@"alt",				
							[NSNumber numberWithInt:kVK_ANSI_KeypadPlus]	,@"numpadplus",		
							[NSNumber numberWithInt:-1]						,@"mousewheelup",		
							[NSNumber numberWithInt:kVK_PageDown]			,@"pagedown",				
							[NSNumber numberWithInt:kVK_ANSI_KeypadClear]	,@"numlock",			
							[NSNumber numberWithInt:-1]						,@"button3",			
							[NSNumber numberWithInt:kUpArrowCharCode]		,@"up",				
							[NSNumber numberWithInt:kVK_ANSI_Keypad2]		,@"numpad2",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad5]		,@"numpad5",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad8]		,@"numpad8",			
							[NSNumber numberWithInt:kVK_End]				,@"end",				
							[NSNumber numberWithInt:kVK_Tab]				,@"tab",				
							[NSNumber numberWithInt:kVK_DownArrow]			,@"down",				
							[NSNumber numberWithInt:kVK_ANSI_KeypadDivide]	,@"numpaddivide",		
							[NSNumber numberWithInt:-1]						,@"button1",			
							[NSNumber numberWithInt:-1]						,@"button4",	
							[NSNumber numberWithInt:-1]						,@"button5",
							[NSNumber numberWithInt:kVK_Delete]				,@"backspace",
							[NSNumber numberWithInt:kVK_ForwardDelete]		,@"delete",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad0]		,@"numpad0",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad3]		,@"numpad3",			
							[NSNumber numberWithInt:kVK_Return]				,@"enter",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad6]		,@"numpad6",			
							[NSNumber numberWithInt:kVK_ANSI_Keypad9]		,@"numpad9",			
							[NSNumber numberWithInt:kVK_F6]					,@"f6",				
							[NSNumber numberWithInt:kVK_PageUp]				,@"pageup",			
							[NSNumber numberWithInt:kVK_Home]				,@"home",				
							[NSNumber numberWithInt:kVK_Escape]				,@"escape",			
							[NSNumber numberWithInt:kVK_ANSI_KeypadMinus]	,@"numpadminus",		
							[NSNumber numberWithInt:kVK_LeftArrow]			,@"left",				
							[NSNumber numberWithInt:kVK_F10]				,@"f10",				
							[NSNumber numberWithInt:kVK_F11]				,@"f11",				
							[NSNumber numberWithInt:kVK_RightArrow]			,@"right",			
							[NSNumber numberWithInt:kVK_F12]				,@"f12",		
							[NSNumber numberWithInt:kVK_F13]				,@"printscreen",	
							[NSNumber numberWithInt:kVK_F14]				,@"f14",	
							[NSNumber numberWithInt:kVK_F15]				,@"f15",	
							[NSNumber numberWithInt:kVK_F16]				,@"f16",	
							[NSNumber numberWithInt:kVK_F17]				,@"f17",	
							[NSNumber numberWithInt:kVK_F18]				,@"f18",	
							[NSNumber numberWithInt:kVK_F19]				,@"f19",	
							nil] retain];
						   
		_bindings = [[NSMutableDictionary dictionary] retain];
		_keyCodesWithCommands = [[NSMutableDictionary dictionary] retain];
		_bindingsToCodes = [[NSMutableDictionary dictionary] retain];
		
		// Notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(playerIsValid:) 
													 name: PlayerIsValidNotification 
												   object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(playerIsInvalid:) 
                                                     name: PlayerIsInvalidNotification 
                                                   object: nil];
    }
    return self;
}

- (void) dealloc{
	[_bindings release]; _bindings = nil;
	[_keyCodesWithCommands release]; _keyCodesWithCommands = nil;
	[_commandToAscii release]; _commandToAscii = nil;
	[_bindingsToCodes release]; _bindingsToCodes = nil;
	[_requiredBindings release]; _requiredBindings = nil;
    [super dealloc];
}

#pragma mark Notifications

- (void)playerIsValid: (NSNotification*)not {
	[self getKeyBindings];
}

- (void)playerIsInvalid: (NSNotification*)not {
	[_bindings removeAllObjects];
	[_keyCodesWithCommands removeAllObjects];
	[_bindingsToCodes removeAllObjects];
}

#pragma mark Key Bindings Scanner

- (void)reloadBindings{
	[self getKeyBindings];
}

typedef struct WoWBinding {
    UInt32 nextBinding;		// 0x0
	UInt32 unknown1;		// 0x4	pointer to a list of something
	UInt32 keyPointer;		// 0x8 (like BACKSPACE)
	UInt32 unknown2;		// 0xC	usually 0
	UInt32 unknown3;		// 0x10	usually 0
	UInt32 unknown4;		// 0x14	usually 0
	UInt32 unknown5;		// 0x18	usually 0
	UInt32 cmdPointer;		// 0x1C (like STRAFELEFT)
} WoWBinding;

- (void)getKeyBindings{
	
	// remove all previous bindings since we're grabbing new ones!
	[_bindings removeAllObjects];
	[_keyCodesWithCommands removeAllObjects];
	
	MemoryAccess *memory = [controller wowMemoryAccess];
	UInt32 offset = [offsetController offset:@"Lua_GetBindingKey"];

	UInt32 bindingsManager = 0, structPointer = 0, firstStruct = 0;
	WoWBinding bindingStruct;
	
	// find the address of our key bindings manager
	if ( [memory loadDataForObject: self atAddress: offset Buffer: (Byte*)&bindingsManager BufLength: sizeof(bindingsManager)] && bindingsManager ){

		// load the first struct
		[memory loadDataForObject: self atAddress: bindingsManager + 0xC4 Buffer: (Byte*)&firstStruct BufLength: sizeof(firstStruct)];
		
		structPointer = firstStruct;
		
		// loop through all structs!
		while ( [memory loadDataForObject: self atAddress: structPointer Buffer: (Byte*)&bindingStruct BufLength: sizeof(bindingStruct)] && bindingStruct.nextBinding > 0x0 && !(bindingStruct.nextBinding & 0x1) ){

			//log(LOG_BINDINGS, @"[Bindings] Struct found at 0x%X", structPointer);

			// initiate our variables
			NSString *key = nil;
			NSString *cmd = nil;
			char tmpKey[64], tmpCmd[64];
			tmpKey[63] = 0;
			tmpCmd[63] = 0;

			if ( [memory loadDataForObject: self atAddress: bindingStruct.keyPointer Buffer: (Byte *)&tmpKey BufLength: sizeof(tmpKey)-1] ){
				key = [NSString stringWithUTF8String: tmpKey];
				//log(LOG_BINDINGS, @"[Bindings] Key %@ found at 0x%X", key, bindingStruct.keyPointer);
			}
			
			if ( [memory loadDataForObject: self atAddress: bindingStruct.cmdPointer Buffer: (Byte *)&tmpCmd BufLength: sizeof(tmpCmd)-1] ){
				cmd = [NSString stringWithUTF8String: tmpCmd];
				//log(LOG_BINDINGS, @"[Bindings] Command %@ found at 0x%X", cmd, bindingStruct.cmdPointer);
			}
			
			// add it
			if ( [key length] && [cmd length] ){
				//log(LOG_BINDINGS, @"%@ -> %@", key, cmd);
				[_bindings setObject:cmd forKey:key];
			}
			
			//log(LOG_BINDINGS, @"[Bindings] Code %d for %@", [chatController keyCodeForCharacter:key], key);
			
			// we already made it through the list! break!
			if ( firstStruct == bindingStruct.nextBinding ){
				break;
			}
			
			// load the next one
			structPointer = bindingStruct.nextBinding;
		}
	}
	
	// now convert!
	[self convertToAscii];
	
	// find codes for our action bars
	[self mapBindingsToKeys];
}


// will convert a single, or a wow-oriented to a code
- (int)toAsciiCode:(NSString*)str{
	
	if ( !str || [str length] == 0 )
		return -1;
	
	// just to be sure
	str = [str lowercaseString];
	
	// single character
	if ( [str length] == 1 ){
		return [chatController keyCodeForCharacter:str];
	}
	
	// string
	else{
		NSNumber *code = [_commandToAscii objectForKey:str];
		
		if ( code ){
			return [code intValue];
		}
	}
	
	return -1;
}

// this function will make me want to kill myself, methinks, is it worth it?  /cry
// converts all of our "text" crap that is in the keybindings file to the actual ascii codes
- (void)convertToAscii{
	
	NSArray *allKeys = [_bindings allKeys];
	NSMutableArray *allCodes = [NSMutableArray array];
	NSMutableArray *unknownCodes = [NSMutableArray array];
	
	for ( NSString *key in allKeys ){
		
		// remove the previous commands
		[allCodes removeAllObjects];
		
		//log(LOG_BINDINGS, @"[Bindings] Command: %@ %@", [_bindings objectForKey:key], key);
		
		// this will tell us where the "-" is in our string!
		int i, splitIndex = -1;
		for ( i = 0; i < [key length]; i++ ){
			unichar code = [key characterAtIndex:i];
			
			if ( code == '-' ){
				splitIndex = i;
				break;
			}
		}
		
		NSString *command1 = nil;
		NSString *command2 = nil;
		NSString *command3 = nil;
		
		// only one command!
		if ( splitIndex == -1 ){
			command1 = [key lowercaseString];

			/*NSString *binding = [[_bindings objectForKey:key] lowercaseString];
			if ( [binding isEqualToString:[[NSString stringWithFormat:@"MULTIACTIONBAR1BUTTON1"] lowercaseString]] ){
				log(LOG_BINDINGS, @" %@", command1);
			}*/
		}
		// 2 commands
		else{
			command1 = [[key substringToIndex:splitIndex] lowercaseString];
			command2 = [[key substringFromIndex:splitIndex+1] lowercaseString];
				
			// make sure it's not just 1 character (i.e. '-')
			if ( [command2 length] > 1 ){
				
				// 2nd command could have another - in it :(  /cry
				splitIndex = -1;
				for ( i = 0; i < [command2 length]; i++ ){
					unichar code = [command2 characterAtIndex:i];
					
					if ( code == '-' ){
						splitIndex = i;
						break;
					}
				}
				
				// 3 keys!
				if ( splitIndex != -1 ){
					NSString *tmp = command2;
					command2 = [[tmp substringToIndex:splitIndex] lowercaseString];
					command3 = [[tmp substringFromIndex:splitIndex+1] lowercaseString];				
				}
			}
		}
		
		// command 1
		if ( command1 && [command1 length] == 1 ){
			[allCodes addObject:[NSNumber numberWithInt:[chatController keyCodeForCharacter:command1]]];
		}
		else if ( command1 && [command1 length] > 0 ){

			int code = [self toAsciiCode:command1];
			if ( code != -1 ){
				[allCodes addObject:[NSNumber numberWithInt:code]];
			}
			else{
				[unknownCodes addObject:command1];
			}
		}
		
		// command 2
		if ( command2 && [command2 length] == 1 ){
			[allCodes addObject:[NSNumber numberWithInt:[chatController keyCodeForCharacter:command2]]];
		}
		else if ( command2 && [command2 length] > 0 ){
			int code = [self toAsciiCode:command2];
			if ( code != -1 ){
				[allCodes addObject:[NSNumber numberWithInt:code]];
			}
			else{
				[unknownCodes addObject:command2];
			}
		}
		
		// command 2
		if ( command3 && [command3 length] == 1 ){
			[allCodes addObject:[NSNumber numberWithInt:[chatController keyCodeForCharacter:command3]]];
		}
		else if ( command3 && [command3 length] > 0 ){
			int code = [self toAsciiCode:command3];
			if ( code != -1 ){
				[allCodes addObject:[NSNumber numberWithInt:code]];
			}
			else{
				[unknownCodes addObject:command3];
			}
		}
		
		// save the codes
		NSString *binding = [[_bindings objectForKey:key] lowercaseString];
		[_keyCodesWithCommands setObject:[allCodes copy] forKey:binding];	
	}
	
	// some error checking pour moi
	if ( [unknownCodes count] ){
		for ( NSString *cmd in unknownCodes ){
			if ( ![_commandToAscii objectForKey:cmd] ){
				log(LOG_BINDINGS, @"[Bindings] Unable to find code for %@, report it to Tanaris4!", cmd);
			}
			//log(LOG_BINDINGS, @" \@\"%@\",", cmd);
		}
	}
}

// pass it MULTIACTIONBAR1BUTTON1
- (NSArray*)bindingForCommand:(NSString*)binding{
	
	NSString *lowerCase = [binding lowercaseString];
	NSArray *codes = [_keyCodesWithCommands objectForKey:lowerCase];

	if ( codes ){
		return codes;
	}
	
	return nil;
}

// grab the key code only
- (int)codeForBinding:(NSString*)binding{
	
	NSArray *codes = [self bindingForCommand:binding];
	
	// find our code
	for ( NSNumber *tehCode in codes ){
		
		int codeVal = [tehCode intValue];
		
		if ( codeVal != kVK_Control && codeVal != kVK_Shift && codeVal != kVK_Option ){
			return codeVal;
		}
	}
	
	return -1;
}

// grab modifiers
- (int)modifierForBinding:(NSString*)binding{
	
	NSArray *codes = [self bindingForCommand:binding];
	
	int modifier = 0;
	
	// find our code + any modifiers
	for ( NSNumber *tehCode in codes ){
		
		int codeVal = [tehCode intValue];
		
		if ( codeVal == kVK_Control ){
			modifier += NSControlKeyMask;
		}
		else if ( codeVal == kVK_Shift ){
			modifier += NSShiftKeyMask;
		}
		else if ( codeVal == kVK_Option ){
			modifier += NSAlternateKeyMask;
		}
	}
	
	return modifier;
}

- (BOOL)bindingForKeyExists:(NSString*)key{

	NSDictionary *dict = [_bindingsToCodes objectForKey:key];
	
	if ( dict && [[dict objectForKey:@"Code"] intValue] >= 0 ){
		return YES;
	}
	
	return NO;
}

// this will do an "intelligent" scan to find our key bindings! Then store them for use! (reset when player is invalid)
- (void)mapBindingsToKeys{
	
	// combine all bindings
	NSMutableArray *allBindings = [NSMutableArray arrayWithArray:_requiredBindings];
	[allBindings addObjectsFromArray:_optionalBindings];
	
	// lets find all the codes!
	for ( NSString *binding in allBindings ){
		
		int code = [self codeForBinding:binding];
		int modifier = [self modifierForBinding:binding];
		
		// we have a valid binding!
		if ( code != -1  ){
			
			// add our object!
			[_bindingsToCodes setObject:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSNumber numberWithInt:code],                 @"Code",
										 [NSNumber numberWithInt:modifier],             @"Modifier",
										 nil]
								 forKey:binding];        // key is something like MULTIACTIONBAR1BUTTON1
		}
		// no binding /cry
		else{
			log(LOG_BINDINGS, @"No valid key binding found for %@", binding);
		}
	}
}

- (BOOL)executeBindingForKey:(NSString*)key{
	
	log(LOG_BINDINGS, @"Executing %@", key);
	
	NSDictionary *dict = [_bindingsToCodes objectForKey:key];
	
	// special case! Try for a backup!
	if ( !dict && [key isEqualToString:BindingPrimaryHotkey] ){
		log(LOG_BINDINGS, @"No code found for %@, searching for %@", key, BindingPrimaryHotkeyBackup);
		dict = [_bindingsToCodes objectForKey:BindingPrimaryHotkeyBackup];
	}
	
	if ( dict ){
		//int offset		= [[dict objectForKey:@"Offset"] intValue];
		int code		= [[dict objectForKey:@"Code"] intValue];
		int modifier	= [[dict objectForKey:@"Modifier"] intValue];
		
		// close chat box?
		if ( [controller isWoWChatBoxOpen] && code != kVK_F13 && code != kVK_F14 && code != kVK_F15){
			[chatController pressHotkey:kVK_Escape withModifier:0x0];
			usleep(10000);
		}
		
		[chatController pressHotkey:code withModifier:modifier];
		
		return YES;
	}
	else{
		log(LOG_BINDINGS, @"[Bindings] Unable to find binding for %@", key);
	}
	
	return NO;
}

- (int)castingBarOffset{
	
	// primary is valid
	if ( [_bindingsToCodes objectForKey:BindingPrimaryHotkey] ){
		return BAR6_OFFSET;
	}
	else if ( [_bindingsToCodes objectForKey:BindingPrimaryHotkeyBackup] ){
		return BAR1_OFFSET;
	}
	
	return -1;
}

// if this string isn't nil, then we are sad + the bot won't start :(
- (NSString*)keyBindingsValid{
	
	// reload bindings
	[self reloadBindings];
	
	BOOL bindingsError = NO;
	NSMutableString *error = [NSMutableString stringWithFormat:@"You need to bind your keys to something! The following aren't bound:\n"];
	if ( ![self bindingForKeyExists:BindingPrimaryHotkey] && ![self bindingForKeyExists:BindingPrimaryHotkeyBackup] ){
		[error appendString:@"\tLower Left Action Bar 1 (Or Action Bar 1)\n"];
		bindingsError = YES;
	}
	else if ( ![self bindingForKeyExists:BindingPetAttack] && [botController.theBehavior usePet] ){
		[error appendString:@"\tPet Attack\n"];
		bindingsError = YES;
	}
	else if ( ![self bindingForKeyExists:BindingInteractMouseover] ){
		[error appendString:@"\tInteract With Mouseover\n"];
		bindingsError = YES;
	}
	else if ( ![self bindingForKeyExists:BindingTargetLast] ){
		[error appendString:@"\tTarget Last Target\n"];
		bindingsError = YES;
	}
	else if ( ![self bindingForKeyExists:BindingTurnLeft] ){
		[error appendString:@"\tTurn Left\n"];
		bindingsError = YES;
	}
	else if ( ![self bindingForKeyExists:BindingTurnRight] ){
		[error appendString:@"\tTurn Right\n"];
		bindingsError = YES;
	}
	else if ( ![self bindingForKeyExists:BindingMoveForward] ){
		[error appendString:@"\tMove Forward\n"];
		bindingsError = YES;
	}
	
	if ( bindingsError ){
		return error;
	}
	
	return nil;     
}

@end
