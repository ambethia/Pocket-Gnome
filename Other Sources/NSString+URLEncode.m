//
//  NSString+URLEncode.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/18/08.
//  Copyright 2008 Savory Software, LLC. All rights reserved.
//

#import "NSString+URLEncode.h"


@implementation NSString (NSString_URLEncode)
- (NSString *)urlEncodeValue {
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
    return [result autorelease];
}
@end
