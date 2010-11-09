//
//  AuraRuleController.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 1/3/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "AuraConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"


@implementation AuraConditionController

- (id) init {
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"AuraCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading AuraCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    // set visibility for dispel/aura components
    BOOL showDispel = (([qualityPopUp selectedTag] == QualityBuffType) || ([qualityPopUp selectedTag] == QualityDebuffType));
    [valueText setHidden: showDispel];
    [typeSegment setHidden: showDispel];
    [dispelTypePopUp setHidden: !showDispel];
}

- (Condition*)condition {
    [self validateState: nil];
    
    BOOL showDispel = (([qualityPopUp selectedTag] == QualityBuffType) || ([qualityPopUp selectedTag] == QualityDebuffType));
    
    id value = nil;
    if(!showDispel) {
        if( [typeSegment selectedTag] == TypeValue )
            value = [NSNumber numberWithInt: [valueText intValue]];
        if( [typeSegment selectedTag] == TypeString )
            value = [valueText stringValue];
    }
    
    Condition *condition = [Condition conditionWithVariety: VarietyAura 
                                                      unit: [[unitPopUp selectedItem] tag]
                                                   quality: [[qualityPopUp selectedItem] tag]
                                                comparator: [[comparatorPopUp selectedItem] tag]
                                                     state: [[dispelTypePopUp selectedItem] tag]
                                                      type: [typeSegment selectedTag]
                                                     value: value];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];

    if( [condition variety] != VarietyAura) return;
    
    //[unitSegment selectSegmentWithTag: [condition unit]];
    
    if(![unitPopUp selectItemWithTag: [condition unit]]) {
        [unitPopUp selectItemWithTag: UnitPlayer];
    }

    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: QualityBuff];
    }
    
    if(![comparatorPopUp selectItemWithTag: [condition comparator]]) {
        [comparatorPopUp selectItemWithTag: CompareExists];
    }
    
    if(![dispelTypePopUp selectItemWithTag: [condition state]]) {
        [dispelTypePopUp selectItemWithTag: StateMagic];
    }
    
    [typeSegment selectSegmentWithTag: [condition type]];
    
    NSString *valueString = nil;
    if( [[condition value] isKindOfClass: [NSString class]] )
        valueString = [condition value];
    else
        valueString = [[condition value] stringValue];
        
    [valueText setStringValue: valueString ? valueString :  @""];        
    
    [self validateState: nil];
    
    //if([condition type] == TypeValue)
    //else
    // [valueText setStringValue: [condition value]];
}

@end
