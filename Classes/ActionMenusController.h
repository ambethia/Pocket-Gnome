//
//  ActionMenusController.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 9/6/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Controller;
@class SpellController;
@class InventoryController;
@class MobController;
@class NodeController;
@class MacroController;

typedef enum ActionMenuTypes {
    MenuType_Spell      = 1,
    MenuType_Inventory  = 2,
    MenuType_Macro      = 3,
    MenuType_Interact   = 5,
    
} ActionMenuType;

@interface ActionMenusController : NSObject {

    IBOutlet Controller				*controller;
    IBOutlet SpellController		*spellController;
    IBOutlet InventoryController	*inventoryController;
    IBOutlet MobController			*mobController;
    IBOutlet NodeController			*nodeController;
	IBOutlet MacroController		*macroController;
}

+ (ActionMenusController *)sharedMenus;

- (NSMenu*)menuType: (ActionMenuType)type actionID: (UInt32)actionID;

@end
