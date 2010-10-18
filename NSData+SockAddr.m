//
//  NSData+SockAddr.m
//  Pocket Gnome
//
//  Created by Jon Drummond on 6/8/05.
//  Copyright 2005 Jon Drummond. All rights reserved.
//

#import "NSData+SockAddr.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "arpa/inet.h"

@implementation NSData (SockAddr)
- (struct sockaddr_in)sockAddrStruct
{
        return *(struct sockaddr_in*)[self bytes];
}
- (unsigned short)dataPort
{
        return ntohs([self sockAddrStruct].sin_port);
}
- (NSString*)ipAddress
{
   return [NSString stringWithCString:inet_ntoa([self sockAddrStruct].sin_addr) encoding:NSASCIIStringEncoding];
}
@end
