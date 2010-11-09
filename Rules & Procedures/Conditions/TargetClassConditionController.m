//
//  TargetClassConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/17/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "TargetClassConditionController.h"


@implementation TargetClassConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"TargetClass" owner: self]) {
            log(LOG_GENERAL, @"Error loading TargetClass.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)awakeFromNib {
    [self validateState: nil];
}

- (IBAction)validateState: (id)sender {
    if([qualitySegment selectedTag] == QualityNPC) {
        if([valuePopUp menu] != creatureTypeMenu)
            [valuePopUp setMenu: creatureTypeMenu];
    } else {
        if([valuePopUp menu] != playerClassMenu)
            [valuePopUp setMenu: playerClassMenu];
    }
    
}

- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyTargetClass 
                                                      unit: UnitTarget
                                                   quality: [qualitySegment selectedTag]
                                                comparator: [comparatorSegment selectedTag]
                                                     state: [[valuePopUp selectedItem] tag]
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyTargetClass) return;

    [comparatorSegment selectSegmentWithTag: [condition comparator]];
	
    [qualitySegment selectSegmentWithTag: [condition quality]];
    [valuePopUp setMenu: creatureTypeMenu];

    [self validateState: nil];
    
    if(![valuePopUp selectItemWithTag: [condition state]]) {
        [valuePopUp selectItemWithTag: 1];
    }
}

@end
