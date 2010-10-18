

#import <Cocoa/Cocoa.h>


@interface NSNumberToHexString : NSValueTransformer {

}

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;

@end
