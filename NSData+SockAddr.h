//
//  NSData+SockAddr.h
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/8/05.
//  Copyright 2005 Jon Drummond. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface NSData (SockAddr)
- (struct sockaddr_in)sockAddrStruct;
- (NSString*)ipAddress;
- (unsigned short)dataPort;
@end
