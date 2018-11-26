//
//  SCChannel.h
//  
//
//  Created by Anatoliy Popov on 20.12.15.
//  Copyright © 2015 Anatoliy Popov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "handlers.h"

@class SCSocket;
@class SCMessage;
typedef enum _CHANNEL_STATE
{

    CHANNEL_STATE_UNSUBSRIBED = 0,
    CHANNEL_STATE_PENDING,
    CHANNEL_STATE_SUBSCRIBED

} CHANNEL_STATE;

@protocol SCChannelDelegate<NSObject>

- (void)SCChannel:(nonnull id/**<>*/)channel receiveData:(nullable id)data;

- (void)SCChannel:(nonnull id/**<>*/)channel kickOutWithMessage:(nullable id)message;

@end

@interface SCChannel : NSObject
@property (weak, nonatomic) SCSocket *socket;
@property (weak, nonatomic) _Nullable id<SCChannelDelegate> delegate;

@property (nonatomic, copy) _Nullable SCChannelUnsubscribeHandler onUnsubscribe;
@property (nonatomic, copy) _Nullable SCChannelSubscribeHandler onSubscribe;
@property (nonatomic, copy) _Nullable SCChannelSubscribeFailHandler onSubscribeFail;
@property (nonatomic, copy) _Nullable SCChannelKickOutHandler onKickOut;
@property (nonatomic, strong) NSString *cid;
@property CHANNEL_STATE state;

- (instancetype)initWithSocket:(SCSocket *)ws andName:(NSString *)name;

- (nonnull NSString *)getName;

- (SCMessage *)message:(id)data;

- (void)watch:(SCDataHandler)handler;

- (void)unwatch:(SCDataHandler)handler;

- (void)callOnData:(id)error response:(id)response;

- (NSInteger)listenerCount;

- (void)unsubscribe;

- (NSString *)subscribe;

- (SCMessage *)publishMessage:(id)data onSuccess:(SCMessageSentHandler)success onFail:(SCMessageSendFailHandler)fail;


- (BOOL)isEqual:(nonnull SCChannel *)object;

@end
