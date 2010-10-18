/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id: MailActionController.m 435 2010-04-23 19:01:10Z ootoaoo $
 *
 */

#import "MailActionController.h"
#import "ActionController.h"
#import "FileObject.h"

@implementation MailActionController : ActionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"MailAction" owner: self]) {
            PGLog(@"Error loading MailAction.nib.");
            _profiles = nil;
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithProfiles: (NSArray*)profiles{
    self = [self init];
    if (self != nil) {
        self.profiles = profiles;
		
		if ( [profiles count] == 0 ){
			[self removeBindings];
			
			NSMenu *menu = [[[NSMenu alloc] initWithTitle: @"No Profiles"] autorelease];
			NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle: @"Create a mail action on the profile tab first!" action: nil keyEquivalent: @""] autorelease];
			[item setIndentationLevel: 1];
			[item setTag:0];
			[menu addItem: item];
			
			[profilesPopUp setMenu:menu];	
		}
    }
    return self;
}

+ (id)mailActionControllerWithProfiles: (NSArray*)profiles{
	return [[[MailActionController alloc] initWithProfiles: profiles] autorelease];
}

// if we don't remove bindings, it won't leave!
- (void)removeBindings{
	
	// no idea why we have to do this, but yea, removing anyways
	NSArray *bindings = [profilesPopUp exposedBindings];
	for ( NSString *binding in bindings ){
		[profilesPopUp unbind: binding];
	}
}

@synthesize profiles = _profiles;

- (IBAction)validateState: (id)sender {
	
}

- (void)setStateFromAction: (Action*)action{
	
	for ( NSMenuItem *item in [profilesPopUp itemArray] ){
		if ( [[(FileObject*)[item representedObject] UUID] isEqualToString:[action value]] ){
			[profilesPopUp selectItem:item];
			break;
		}
	}
	
	[super setStateFromAction:action];
}

- (Action*)action {
    [self validateState: nil];
    
    Action *action = [Action actionWithType:ActionType_Mail value:nil];
	id value = [(FileObject*)[[profilesPopUp selectedItem] representedObject] UUID];
	
	[action setEnabled: self.enabled];
    [action setValue: value];
	
    return action;
}

@end
