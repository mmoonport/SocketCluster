//
// Created by Matthew Moon on 11/23/18.
//

#import "SCMessageHandler.h"
#import "SCSocket.h"
#import "SCChannel.h"
#import "SCMessage.h"

NSString *PING_MESSAGE = @"#1";
NSString *SET_AUTH = @"#setAuthToken";
NSString *PUBLISH = @"#publish";
NSString *FAIL = @"#fail";
NSString *KICK_OUT = @"#kickOut";
NSString *UNSET_AUTH = @"#removeAuthToken";
NSString *DISCONNECT = @"#disconnect";

@interface SCMessageHandler ()
@property (nonatomic, strong) SCSocket *socket;
@end

@implementation SCMessageHandler
- (instancetype)initWithSocketCluster:(SCSocket *)socket
{
    self = [super init];
    if (self) {
        self.socket = socket;
    }

    return self;
}

- (void)didReceiveMessage:(NSString *)string
{
    if ([string isEqualToString:PING_MESSAGE]) {
        [self.socket pong];
    } else {
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        [self didReceiveData:data];
    }
}

- (void)didReceiveData:(NSData *)data
{
    NSError *error;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!dictionary) {
        return;
    }

    NSString *rid = [[dictionary valueForKey:@"rid"] stringValue];
    id errorData = dictionary[@"error"];
    NSDictionary *response = dictionary[@"data"];
    NSString *event = [dictionary[@"eventName"] stringValue];
    if (rid) {
        SCChannel *channel = [self channelForID:rid];
        SCMessage *message = [self messageForID:rid];
        if ([channel isKindOfClass:[SCChannel class]]) {
            if (errorData && ![errorData isKindOfClass:[NSNull class]]) {
                channel.state = CHANNEL_STATE_UNSUBSRIBED;
                if (channel.onSubscribeFail) {
                    channel.onSubscribeFail(nil, errorData);
                }
                [self.channels removeObject:channel];

            } else {
                channel.state = CHANNEL_STATE_SUBSCRIBED;
                if (channel.onSubscribe) {
                    channel.onSubscribe(response);
                }
            }
        } else if ([message isKindOfClass:[SCMessage class]]) {
            [self.messages removeObject:message];
            if (errorData && ![errorData isKindOfClass:[NSNull class]]) {
                if (message.onFail) {
                    message.onFail(nil, errorData);
                }

            } else {
                if (message.onSuccess) {
                    message.onSuccess(message, response);
                }
            }
        }
    } else if (event) {
        BOOL stdRTEvent = NO;
        if ([event isEqualToString:SET_AUTH]) {
            stdRTEvent = YES;
            [self.socket setAuth:response];
        } else if ([event isEqualToString:UNSET_AUTH]) {
            stdRTEvent = YES;
            [self.socket unsetAuth];
        } else if ([event isEqualToString:PUBLISH]) {
            stdRTEvent = YES;
            [self handlePublish:response];
        } else if ([event isEqualToString:FAIL]) {
            stdRTEvent = YES;
        } else if ([event isEqualToString:KICK_OUT]) {
            stdRTEvent = YES;
            [self handleKickOut:response];
        } else if ([event isEqualToString:DISCONNECT]) {
            stdRTEvent = YES;
            self.channels = [NSMutableArray new];
            self.messages = [NSMutableArray new];
            [self.socket disconnect];
        }

        [self.socket handleWatchers:event data:response error:errorData];

        if ([self.socket.delegate conformsToProtocol:@protocol(SCSocketDelegate)]) {
            if ([self.socket.delegate respondsToSelector:@selector(socketClusterDidReceiveData:)]) {
                [self.socket.delegate socketClusterDidReceiveData:(id) response];
            }
        }

    }

}

- (void)handleKickOut:(NSDictionary *)dictionary
{
    NSString *channelName = dictionary[@"channel"];

    if ([channelName isKindOfClass:[NSString class]]) {
        SCChannel *channel = [self channelForName:channelName];
        if (channel) {
            [self.channels removeObject:channel];
            id message = dictionary[@"message"];

            if (channel.onKickOut) {
                channel.onKickOut(message);
            }
        }
    }
}

- (void)handlePublish:(NSDictionary *)dictionary
{

    NSString *channelName = dictionary[@"channel"];

    if ([channelName isKindOfClass:[NSString class]]) {
        SCChannel *channel = [self channelForName:channelName];
        if (channel) {
            [self.channels removeObject:channel];
            id data = dictionary[@"data"];

            if (channel.listenerCount) {
                [channel callOnData:nil response:data];
            } else {
                [self.channels removeObject:channel];
            }
        }
    }
}

- (SCMessage *)messageForID:(NSString *)rid
{
    return self.messages[[[self.messages valueForKey:@"cid"] indexOfObject:rid]];
}

- (SCChannel *)channelForName:(NSString *)name
{
    return self.channels[[[self.channels valueForKey:@"name"] indexOfObject:name]];
}

- (SCChannel *)channelForID:(NSString *)rid
{
    return self.channels[[[self.channels valueForKey:@"cid"] indexOfObject:rid]];
}

- (void)restoreConnection
{
    for (SCChannel *channel in self.channels) {
        if (channel.state == CHANNEL_STATE_SUBSCRIBED) {
            [self.socket emit:@"#subscribe" data:@{@"channel": [channel getName]}];
        }
    }

    for (SCMessage *message in self.messages) {
        if (![message.eventName isEqualToString:@"#handshake"]) {
            [self.socket emitEvent:message.event];
        }
    }
}
@end
