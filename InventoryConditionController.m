//
//  InventoryConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/18/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "InventoryConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation InventoryConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"InventoryCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading InventoryCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    //[qualitySegment selectSegmentWithTag: QualityInventory];
}

- (Condition*)condition {
    [self validateState: nil];
    
    int quantity = [quantityText intValue];
    if(quantity < 0) quantity = 0;
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue ) {
        NSString *string = [[itemText stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        value = [NSNumber numberWithInt: [string intValue]];
    }
    if( [typeSegment selectedTag] == TypeString )
        value = [itemText stringValue];
        
    Condition *condition = [Condition conditionWithVariety: VarietyInventory
                                                      unit: UnitPlayer 
                                                   quality: QualityInventory
                                                comparator: [[comparatorPopUp selectedItem] tag] 
                                                     state: quantity
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyInventory) return;
    
    [typeSegment selectSegmentWithTag: [condition type]];
    //[unitSegment selectSegmentWithTag: [condition unit]];
    //[qualitySegment selectSegmentWithTag: [condition quality]];
    //[comparatorSegment selectSegmentWithTag: [condition comparator]];

    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareMore];
    }
    
    // set quantity text with value from state variable
    [quantityText setStringValue: [NSString stringWithFormat: @"%d", [condition state]]];
    
    if( [[condition value] isKindOfClass: [NSString class]] )
        [itemText setStringValue: [condition value]];
    else
        [itemText setStringValue: [[condition value] stringValue]];
}

@end
