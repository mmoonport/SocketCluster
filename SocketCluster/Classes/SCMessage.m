//
//  SCMessage.m
//
//
//  Created by Anatoliy Popov on 20.12.15.
//  Copyright © 2015 Anatoliy Popov. All rights reserved.
//

#import "SCMessage.h"
#import "SCSocket.h"
#import "SCChannel.h"
#import "SCMessageHandler.h"

@implementation SCMessage

- (instancetype)initWithSocket:(SCSocket *)socket andEventName:(nullable NSString *)eventName andData:(nullable id)data
{
    self = [super init];
    if (self) {
        self.socket = socket;
        self.data = data;
        self.eventName = eventName;
        self.event = nil;
    }
    return self;
}

- (NSString *)sendToChannel:(SCChannel *)channel
{
    [self.socket.messageHandler.messages addObject:self];
    self.event = [self.socket emit:@"#publish" data:@{@"channel": [channel getName], @"data": self.data}];
    self.cid = self.event[@"cid"];
    return self.cid;

}

- (NSString *)send
{
    if (self.channel) {
        return [self sendToChannel:self.channel];
    }
    [self.socket.messageHandler.messages addObject:self];
    self.event = [self.socket emit:self.eventName data:self.data];
    self.cid = self.event[@"cid"];
    return self.cid;
}

- (BOOL)isEqual:(nonnull SCMessage *)object
{
    return [object isKindOfClass:[SCMessage class]] && object.cid == self.cid;
}

@end
