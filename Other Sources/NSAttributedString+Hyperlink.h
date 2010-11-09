//
//  NSAttributedString+Hyperlink.h
//  Pocket Gnome
//
//  Created by Josh on 10/28/10.
//  Copyright 2010 Savory Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end