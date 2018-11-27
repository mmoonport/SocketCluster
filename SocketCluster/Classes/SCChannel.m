//
//  SCChannel.m
//  
//
//  Created by Anatoliy Popov on 20.12.15.
//  Copyright © 2015 Anatoliy Popov. All rights reserved.
//

#import "SCChannel.h"
#import "SCSocket.h"
#import "SCMessage.h"
#import "SCMessageHandler.h"

@implementation SCChannel
{
    NSString *channelName;
    NSMutableArray<SCDataHandler> *onDataBlocks;

}

- (instancetype)initWithSocket:(SCSocket *)ws andName:(NSString *)name
{
    self = [super init];
    if (self) {

        channelName = name;
        _socket = ws;
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
    SCMessage *message = [[SCMessage alloc] initWithSocket:_socket andEventName:nil andData:data];
    message.channel = self;
    return message;
}

- (void)watch:(SCDataHandler)handler
{
    if (![onDataBlocks containsObject:handler]) {
        [onDataBlocks addObject:handler];
    }
    if (self.state != CHANNEL_STATE_PENDING) {
        [self subscribe];
    }
}

- (void)unwatch:(SCDataHandler)handler
{
    [onDataBlocks removeObject:handler];
    if (![onDataBlocks count]) {
        [self unsubscribe];
    }
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
    if ([_socket.messageHandler channelForName:[self getName]]) {
        SCMessage *message = [[SCMessage alloc] initWithSocket:_socket andEventName:@"#unsubscribe" andData:[self getName]];
        message.onSuccess = ^(SCMessage *message, id response) {
            [self->_socket.messageHandler.channels removeObject:self];
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
    if ([_socket.messageHandler channelForName:[self getName]]) {
        [_socket.messageHandler.channels removeObject:self];
    }

    SCMessage *message = [[SCMessage alloc] initWithSocket:_socket andEventName:@"#subscribe" andData:[self getName]];
    message.onSuccess = ^(SCMessage *message, id response) {
        [self->_socket.messageHandler.channels addObject:self];
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
    SCMessage *msg = [[SCMessage alloc] initWithSocket:_socket andEventName:nil andData:data];
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
