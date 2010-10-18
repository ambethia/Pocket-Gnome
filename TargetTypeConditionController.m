//
//  TargetTypeConditionController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 8/17/08.
//  Copyright 2008 Jon Drummond. All rights reserved.
//

#import "TargetTypeConditionController.h"


@implementation TargetTypeConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"TargetType" owner: self]) {
            log(LOG_GENERAL, @"Error loading TargetType.nib.");
            
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
        [displayText setStringValue: @"Target is an"];
    } else {
        [displayText setStringValue: @"Target is a"];
    }
}

- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyTargetType 
                                                      unit: UnitTarget
                                                   quality: [qualitySegment selectedTag]
                                                comparator: CompareIs
                                                     state: StateNone
                                                      type: TypeNone
                                                     value: nil];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyTargetType) return;
    
    [qualitySegment selectSegmentWithTag: [condition quality]];
    
    [self validateState: nil];
}

@end
