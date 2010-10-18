
#import "NSNumberToHexString.h"


@implementation NSNumberToHexString

+ (Class)transformedValueClass;
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation;
{
    return NO;   
}

- (id)transformedValue:(id)value;
{
    if(!value)  return @"(nil)";
    return [NSString stringWithFormat: @"0x%X", [value unsignedIntValue]];
}

@end
