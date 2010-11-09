/*
 * Copyright (c) 2007-2010 Savory Software, LLC, http://pg.savorydeviate.com/
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * $Id: MailActionProfile.h 315 2010-04-17 04:12:45Z Tanaris4 $
 *
 */

#import <Cocoa/Cocoa.h>
#import "Profile.h"

@interface MailActionProfile : Profile {
	
	BOOL _qualityPoor, _qualityCommon, _qualityUncommon, _qualityRare, _qualityEpic, _qualityLegendary;
	BOOL _includeItems, _excludeItems;
	NSString *_itemsToInclude, *_itemsToExclude, *_sendTo;
}

+ (id)mailActionProfileWithName: (NSString*)name;

@property (readwrite, assign) BOOL qualityPoor;
@property (readwrite, assign) BOOL qualityCommon;
@property (readwrite, assign) BOOL qualityUncommon;
@property (readwrite, assign) BOOL qualityRare;
@property (readwrite, assign) BOOL qualityEpic;
@property (readwrite, assign) BOOL qualityLegendary;
@property (readwrite, assign) BOOL includeItems;
@property (readwrite, assign) BOOL excludeItems;
@property (readwrite, copy) NSString *itemsToInclude;
@property (readwrite, copy) NSString *itemsToExclude;
@property (readwrite, copy) NSString *sendTo;

// returns an array of the names trimmed
- (NSArray*)inclusions;
- (NSArray*)exclusions;

@end