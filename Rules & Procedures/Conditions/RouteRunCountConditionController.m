//
//  RouteRunCountConditionController.m
//  Pocket Gnome
//
//  Created by Josh on 1/13/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import "RouteRunCountConditionController.h"


@implementation RouteRunCountConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"RouteRunCountCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading RouteRunCountCondition.nib.");
            
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
	
	Condition *condition = [Condition conditionWithVariety: VarietyRouteRunCount 
													  unit: UnitNone
												   quality: QualityNone
												comparator: [comparatorSegment selectedTag]
													 state: StateNone
													  type: TypeValue
													 value: [NSNumber numberWithInt:[quantityText intValue]]];
	[condition setEnabled: self.enabled];
	
	return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
	[super setStateFromCondition: condition];
	if( [condition variety] != VarietyRouteRunCount) return;
	
	[comparatorSegment selectSegmentWithTag: [condition comparator]];
	
	[quantityText setStringValue: [[condition value] stringValue]];
}


@end
