#import "HealthConditionController.h"
#import "ConditionController.h"
#import "BetterSegmentedControl.h"

@implementation HealthConditionController

- (id) init
{
    self = [super init];
    if (self != nil) {
        if(![NSBundle loadNibNamed: @"HealthCondition" owner: self]) {
            log(LOG_GENERAL, @"Error loading HealthCondition.nib.");
            
            [self release];
            self = nil;
        }
    }
    return self;
}

- (IBAction)validateState: (id)sender {
    // target health must be in %
    if( ([unitSegment selectedTag] == UnitTarget) && ([[qualityPopUp selectedItem] tag] == QualityHealth) ) {
        [typeSegment selectSegmentWithTag: TypePercent];
    }
    
    // pet happiness must be in %
    if( ([unitSegment selectedTag] == UnitPlayerPet) && ([[qualityPopUp selectedItem] tag] == QualityHappiness) ) {
        [typeSegment selectSegmentWithTag: TypePercent];
    }
}


- (Condition*)condition {
    [self validateState: nil];
    
    Condition *condition = [Condition conditionWithVariety: VarietyPower 
                                                      unit: [unitSegment selectedTag] 
                                                   quality: [[qualityPopUp selectedItem] tag] // [qualitySegment selectedTag] 
                                                comparator: [comparatorSegment selectedTag] 
                                                     state: StateNone
                                                      type: [typeSegment selectedTag]
                                                     value: [NSNumber numberWithInt: [quantityText intValue]]];
    [condition setEnabled: self.enabled];
    
    return condition;
}

- (void)setStateFromCondition: (Condition*)condition {
    [super setStateFromCondition: condition];
    if( [condition variety] != VarietyPower) return;
    
    [unitSegment selectSegmentWithTag: [condition unit]];
    if(![qualityPopUp selectItemWithTag: [condition quality]]) {
        [qualityPopUp selectItemWithTag: 2];
    }
    //[qualitySegment selectSegmentWithTag: [condition quality]];
    [comparatorSegment selectSegmentWithTag: [condition comparator]];
    [typeSegment selectSegmentWithTag: [condition type]];
    
    [quantityText setStringValue: [[condition value] stringValue]];
}

@end
