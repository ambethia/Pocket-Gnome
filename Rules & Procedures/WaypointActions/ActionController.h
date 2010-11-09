//
//  ActionController.h
//  Pocket Gnome
//
//  Created by Josh on 1/14/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"

@interface ActionController : NSObject {
    IBOutlet NSView *view;
    IBOutlet id _delegate;
    IBOutlet NSButton *disableButton;
    BOOL _enabled;
}

+ (id)actionControllerWithAction: (Action*)action;

- (NSView*)view;
- (IBAction)validateState: (id)sender;
- (IBAction)disableAction: (id)sender;

@property (readwrite, assign) id delegate;
@property BOOL enabled;

- (Action*)action;
- (void)setStateFromAction: (Action*)action;
- (void)removeBindings;

@end
