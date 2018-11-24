//
//  SCChannel.m
//  
//
//  Created by Anatoliy Popov on 20.12.15.
//  Copyright © 2015 Anatoliy Popov. All rights reserved.
//

#import "SCChannel.h"
#import "SCSocket.h"

#import "SCMessageHandler.h"

@implementation SCChannel
{
    NSString *channelName;
    SCSocket *socket;
    NSMutableArray<SCDataHandler> *onDataBlocks;

}

- (instancetype)initWithSocket:(SCSocket *)ws andName:(NSString *)name
{
    self = [super init];
    if (self) {

        channelName = name;
        socket = ws;
        onDataBlocks = [NSMutableArray new];
    }
    return self;
}

- (NSString *)getName
{

    return channelName;
}

- (SCMessage *)message:(id)data
{
    SCMessage *message = [[SCMessage alloc] initWithSocket:socket andEventName:nil andData:data];
    message.channel = self;
    return message;
}

- (void)watch:(SCDataHandler)handler
{
    if (![onDataBlocks containsObject:handler]) {
        [onDataBlocks addObject:handler];
    }

}

- (void)unwatch:(SCDataHandler)handler
{
    [onDataBlocks removeObject:handler];
}

- (void)callOnData:(id)error response:(id)response
{
    for (SCDataHandler handler in onDataBlocks) {
        handler(error, response);
    }
}

- (NSInteger)listenerCount
{
    return [onDataBlocks count];
}

- (void)unsubscribe
{
    if ([socket.messageHandler channelForName:[self getName]]) {
        SCMessage *message = [[SCMessage alloc] initWithSocket:socket andEventName:@"#unsubscribe" andData:[self getName]];
        message.onSuccess = ^(SCMessage *message, id response) {
            [socket.messageHandler.channels removeObject:self];
            if (self.onUnsubscribe) {
                self.onUnsubscribe();
            }
        };
        self.state = CHANNEL_STATE_PENDING;
        [message send];
    }
}

- (NSString *)subscribe
{
    if ([socket.messageHandler channelForName:[self getName]]) {
        [socket.messageHandler.channels removeObject:self];
    }

    SCMessage *message = [[SCMessage alloc] initWithSocket:socket andEventName:@"#subscribe" andData:[self getName]];
    message.onSuccess = ^(SCMessage *message, id response) {
        [socket.messageHandler.channels addObject:self];
        if (self.onSubscribe) {
            self.onSubscribe(response);
        }
    };
    self.state = CHANNEL_STATE_PENDING;
    self.cid = [message send];

    return self.cid;
}

- (SCMessage *)publishMessage:(id)data onSuccess:(SCMessageSentHandler)success onFail:(SCMessageSendFailHandler)fail
{
    SCMessage *msg = [[SCMessage alloc] initWithSocket:socket andEventName:nil andData:data];
    msg.onSuccess = success;
    msg.onFail = fail;
    [msg sendToChannel:self];
    return msg;
}

- (BOOL)isEqual:(SCChannel *)object
{
    return [channelName isEqualToString:[object getName]];
}

@end
