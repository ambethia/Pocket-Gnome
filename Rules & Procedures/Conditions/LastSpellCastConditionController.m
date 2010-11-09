//
//  LastSpellCastConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 12/28/09.
//  Copyright 2009 Savory Software, LLC. All rights reserved.
//

#import "LastSpellCastConditionController.h"


@implementation LastSpellCastConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"LastSpellCast" owner: self]) {
            log(LOG_GENERAL, @"Error loading LastSpellCast.nib.");
            
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
    
    id value = nil;
    if( [typeSegment selectedTag] == TypeValue )
        value = [NSNumber numberWithInt: [valueText intValue]];
    if( [typeSegment selectedTag] == TypeString )
        value = [valueText stringValue];
    
    Condition *condition = [Condition conditionWithVariety: VarietyLastSpellCast 
                                                      unit: UnitNone
                                                   quality: QualityNone
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: StateNone
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
	
    if( [condition variety] != VarietyLastSpellCast ) return;
	
	if ( ![comparatorPopUp selectItemWithTag: [condition comparator]] ) {
        [comparatorPopUp selectItemWithTag: CompareIs];
    }
    
    [typeSegment selectSegmentWithTag: [condition type]];
	[valueText setStringValue:[NSString stringWithFormat:@"%@", [condition value]]];
	
    [self validateState: nil];
}

@end
