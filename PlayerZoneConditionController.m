//
//  ZoneConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "PlayerZoneConditionController.h"


@implementation PlayerZoneConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"PlayerZoneCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading PlayerZoneCondition.nib.");
            
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
	
	Condition *condition = [Condition conditionWithVariety: VarietyPlayerZone 
													  unit: UnitNone
												   quality: QualityNone
												comparator: [comparatorSegment selectedTag]
													 state: StateNone
													  type: [typeSegment selectedTag]
													 value: [NSNumber numberWithInt:[quantityText intValue]]];
	[condition setEnabled: self.enabled];
	
	return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
	[super setStateFromCondition: condition];
	if( [condition variety] != VarietyPlayerZone) return;
	
	[comparatorSegment selectSegmentWithTag: [condition comparator]];
	[typeSegment selectSegmentWithTag: [condition type]];
	
	[quantityText setStringValue: [[condition value] stringValue]];
}

@end
