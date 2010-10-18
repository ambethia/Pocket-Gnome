#import <Cocoa/Cocoa.h>
#import "ConditionController.h"

@class BetterSegmentedControl;

@interface HealthConditionController : ConditionController {
    IBOutlet BetterSegmentedControl *unitSegment;
    IBOutlet BetterSegmentedControl *qualitySegment;
    IBOutlet NSPopUpButton *qualityPopUp;
    IBOutlet BetterSegmentedControl *comparatorSegment;
    IBOutlet NSTextField *quantityText;
    IBOutlet BetterSegmentedControl *typeSegment;

}

@end
