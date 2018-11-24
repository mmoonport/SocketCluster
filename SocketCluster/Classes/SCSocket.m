//
//  SCSocket.m
//  SocketCluster
//
//  Created by Matthew Moon on 11/23/18.
//

#import "SCSocket.h"
#import "JFRWebSocket.h"
#import "SCMessageHandler.h"
#import "NSDictionary+SocketCluster.h"

@interface SCSocket ()<JFRWebSocketDelegate>
@property (nonatomic, strong) JFRWebSocket *socket;
@end

@implementation SCSocket
{
    NSMutableDictionary<NSString *, NSMutableArray<SCDataHandler> *> *eventWatchers;
}

#pragma mark - Public Methods

@synthesize eventWatchers;

- (instancetype)initWithURL:(NSString *)url isSecure:(BOOL)secure
{
    self = [super init];
    if (self) {
        NSString *prefix = secure ? @"wss" : @"ws";
        self.reconnectTimeout = 5;
        self.maxReconnectTimeout = 10;
        self.url = [[NSURL new] initWithString:[NSString stringWithFormat:@"%@://%@?transport=websocket", prefix, url]];
        self.messageHandler = [[SCMessageHandler alloc] initWithSocketCluster:self];
        self.socket = [[JFRWebSocket alloc] initWithURL:self.url protocols:@[]];
        self.socket.delegate = self;
        eventWatchers = [NSMutableDictionary<NSString *, NSMutableArray<SCDataHandler> *> new];

    }

    return self;
}

- (BOOL)isConnected
{
    return self.socket && self.socket.isConnected;
}


- (void)connect
{
    [self.socket connect];
}

- (void)disconnect
{
    [self handleDisconnect];
}

- (void)pause
{
    self.reconnecting = YES;
    self.isPaused = YES;
    [self.socket disconnect];
}

- (void)watch:(NSString *)eventName handler:(SCDataHandler)handler
{
    if (![[eventWatchers allKeys] containsObject:eventName]) {
        eventWatchers[eventName] = [NSMutableArray<SCDataHandler> new];
    }
    [eventWatchers[eventName] addObject:handler];
}

- (void)unwatch:(NSString *)eventName handler:(nullable SCDataHandler)handler
{
    if (handler == nil) {
        [eventWatchers removeObjectForKey:eventName];
    } else if ([[eventWatchers allKeys] containsObject:eventName]) {
        [eventWatchers[eventName] removeObject:handler];
    }
}

- (void)handleWatchers:(NSString *)eventName data:(id)data error:(id)error
{
    if ([[eventWatchers allKeys] containsObject:eventName]) {
        for (SCDataHandler handler in eventWatchers[eventName]) {
            handler(error, data);
        }
    }
}

- (NSDictionary *)emit:(NSString *)eventName data:(id)data
{
    NSString *cid = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *event = [@{
            @"eventName": eventName,
            @"cid": cid
    } mutableCopy];
    if (data) {
        event[@"data"] = data;
    }
    [self emitEvent:event];
    return event;
}

- (void)emitEvent:(NSDictionary *)event
{
    if ([self.socket isConnected]) {
        [self.socket writeData:[event toJSON:nil]];
    }
}

- (SCChannel *)channel:(NSString *)channelName
{
    SCChannel *channel = [self.messageHandler channelForName:channelName];
    if (!channel) {
        channel = [[SCChannel alloc] initWithSocket:self andName:channelName];
    }
    return channel;
}

- (SCMessage *)message:(nullable NSString *)eventName data:(nullable id)data
{
    return [[SCMessage alloc] initWithSocket:self andEventName:eventName andData:data];
}

- (void)login:(nullable NSDictionary *)data withSuccess:(SCMessageSentHandler)success withFail:(SCMessageSendFailHandler)fail
{
    SCMessage *message = [[SCMessage alloc] initWithSocket:self andEventName:@"login" andData:data];
    message.onSuccess = success;
    message.onFail = fail;
    [message send];
}

- (void)authenticate:(NSString *)authToken onSuccess:(nullable void (^)(NSString *token))success onFail:(nullable void (^)(NSDictionary *error))fail
{
    SCMessage *authenticateMessage = [[SCMessage alloc] initWithSocket:self andEventName:@"#authenticate" andData:@{@"authToken": authToken}];
    authenticateMessage.onSuccess = ^(SCMessage *message, id response) {
        NSDictionary *authStatus = (NSDictionary *) response;
        if ([authStatus isKindOfClass:[NSDictionary class]]) {
            if ([authStatus[@"isAuthenticated"] boolValue]) {
                [self setAuth:@{@"token": authToken}];
            } else {
                [self unsetAuth];
            }
        }
    };
    authenticateMessage.onFail = ^(SCMessage *message, id response) {
        [self unsetAuth];
    };
    [authenticateMessage send];

}

- (void)setAuth:(NSDictionary *)dictionary
{
    NSString *token = [dictionary[@"token"] stringValue];

    if (token && ![token isKindOfClass:[NSNull class]] && [token length] > 0) {
        self.authToken = token;

        if (self.waitResendUntilAuth && self.restoreChannels && self.reconnecting) {
            [self.messageHandler restoreConnection];
        }

        self.reconnecting = NO;


        if ([self.delegate respondsToSelector:@selector(socketClusterAuthenticateEvent:)]) {
            [self.delegate socketClusterAuthenticateEvent:token];
        }
    }
}


- (void)unsetAuth
{
    self.authToken = nil;
    self.isAuthenticated = NO;
}

#pragma mark - JFRWebSocketDelegate

- (void)websocketDidConnect:(JFRWebSocket *)socket
{
    [self handleConnect];
}

- (void)websocketDidDisconnect:(JFRWebSocket *)socket error:(NSError *)error
{
    [self handleDisconnect];
}

- (void)websocket:(JFRWebSocket *)socket didReceiveMessage:(NSString *)string
{
    [self.messageHandler didReceiveMessage:string];
}

- (void)websocket:(JFRWebSocket *)socket didReceiveData:(NSData *)data
{
    [self.messageHandler didReceiveData:data];
}

# pragma mark - Private Methods

- (void)handleConnect
{
    SCMessage *handShakeMessage = [[SCMessage alloc] initWithSocket:self andEventName:@"#handshake" andData:nil];
    if (self.authToken && [self.authToken isKindOfClass:[NSString class]]) {
        handShakeMessage.data = @{@"authToken": self.authToken};
    }

    handShakeMessage.onSuccess = ^(SCMessage *message, id response) {
        if (![response isKindOfClass:[NSNull class]]) {

            BOOL isAuthenticated = [response[@"isAuthenticated"] boolValue];
            NSString *idx = [response objectForKey:@"id"];
            if ([idx isKindOfClass:[NSString class]] && isAuthenticated != nil) {
                self.socketId = idx;
                self.isAuthenticated = isAuthenticated;

                if (!self.isAuthenticated) {
                    self.authToken = nil;
                }
                BOOL reconnect = self.reconnecting;
                if (reconnect) {
                    if (!self.waitResendUntilAuth || self.isAuthenticated) {
                        self.reconnecting = NO;
                        [self.messageHandler restoreConnection];
                    }

                }

                if ([self.delegate respondsToSelector:@selector(socketClusterConnectEvent:)]) {
                    [self.delegate socketClusterConnectEvent:reconnect];
                }
            }
        }
    };
    [handShakeMessage send];
}

- (void)handleDisconnect
{
    if (self.reconnectTimeout > 0) {

        NSInteger randReconnectTime = arc4random() % (self.maxReconnectTimeout - self.reconnectTimeout) + self.reconnectTimeout;

        self.reconnecting = YES;

        [self performSelector:@selector(connect) withObject:nil afterDelay:randReconnectTime];
    } else {
        [self unsetAuth];
        self.reconnectTimeout = -1;
        [self.socket disconnect];
    }

}

- (void)pong
{
    [self.socket writeString:@"2"];
}
@end
