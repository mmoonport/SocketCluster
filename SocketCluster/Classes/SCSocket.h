//
//  SCSocket.h
//  SocketCluster
//
//  Created by Matthew Moon on 11/23/18.
//

#import <Foundation/Foundation.h>

@class JFRWebSocket;
@protocol JFRWebSocketDelegate;
@class SCMessageHandler;
@class SCSocket;
@class SCChannel;
@class SCMessage;

NS_ASSUME_NONNULL_BEGIN

typedef void(^SCDataHandler)(_Nullable id error, _Nullable id response);

@protocol SCSocketDelegate<NSObject>
- (void)socketClusterDidConnect:(SCSocket *)socket;

- (void)socketClusterDidDisconnect:(SCSocket *)socket;

- (void)socketClusterDidReceiveData:(id)message;

- (void)socketClusterAuthenticateEvent:(NSString *_Nonnull)token;

- (void)socketClusterConnectEvent:(BOOL)reconnecting;

- (void)socketClusterReceivedEvent:(NSString *_Nonnull)eventName WithData:(NSDictionary *_Nullable)data isStandartEvent:(BOOL)isStandartEvent;
@end


@interface SCSocket : NSObject
@property (nonatomic, strong) SCMessageHandler *messageHandler;
@property (nonatomic, copy) NSURL *url;
@property (assign, nonatomic, nullable) id<SCSocketDelegate> delegate;
@property (nonatomic, strong) NSString *authToken;
@property (nonatomic, copy) NSString *socketId;
@property (nonatomic) BOOL isAuthenticated;
@property (nonatomic) BOOL reconnecting;
@property (nonatomic) BOOL restoreChannels;
@property (nonatomic) BOOL waitResendUntilAuth;

@property (nonatomic) int reconnectTimeout;
@property (nonatomic) int maxReconnectTimeout;

@property (nonatomic) BOOL isPaused;

@property (nonatomic, strong) NSMutableDictionary *eventWatchers;

- (instancetype)initWithURL:(NSString *)url isSecure:(BOOL)secure;

- (void)connect;

- (void)emitEvent:(NSDictionary *)event;

- (SCChannel *)channel:(NSString *)channelName;

- (SCMessage *)message:(nullable NSString *)eventName data:(nullable id)data;

- (void)login:(nullable NSDictionary *)data withSuccess:(SCMessageSentHandler)success withFail:(SCMessageSendFailHandler)fail;

- (void)authenticate:(NSString *)authToken onSuccess:(nullable void (^)(NSString *token))success onFail:(nullable void (^)(NSDictionary *error))fail;

- (void)setAuth:(NSDictionary *)dictionary;

- (BOOL)isConnected;

- (void)unsetAuth;

- (void)pong;

- (void)disconnect;

- (void)pause;

- (void)watch:(NSString *)eventName handler:(SCDataHandler)handler;

- (void)unwatch:(NSString *)eventName handler:(nullable SCDataHandler)handler;

- (void)handleWatchers:(NSString *)eventName data:(id)data error:(id)error;

- (NSDictionary *)emit:(NSString *)eventName data:(id)data;
@end

NS_ASSUME_NONNULL_END
