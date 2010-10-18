//
//  RuneConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/7/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "RuneConditionController.h"
#import "ConditionController.h"

@implementation RuneConditionController


- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"RuneCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading RuneCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {

}


- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyRune 
                                                      unit: UnitTarget
                                                   quality: [[qualityPopUp selectedItem] tag] // [qualitySegment selectedTag] 
                                                comparator: [comparatorSegment selectedTag]
                                                     state: StateNone
                                                      type: TypeValue
                                                     value: [NSNumber numberWithInt:[[quantityPopUp selectedItem] tag]]];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyRune) return;
    
    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: 21];
    }
	
    if(![quantityPopUp selectItemWithTag: [[condition value] intValue]]) {
        [quantityPopUp selectItemWithTag: 1];
    }
	[comparatorSegment selectSegmentWithTag: [condition comparator]];
}

@end
