//
//  SCMessage.h
//  
//
//  Created by Anatoliy Popov on 20.12.15.
//  Copyright © 2015 Anatoliy Popov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCChannel;
@class SCSocket;

typedef void(^SCMessageSentHandler)(_Nonnull id message, _Nullable id response);

typedef void(^SCMessageSendFailHandler)(_Nonnull id message, _Nullable id response);


@interface SCMessage : NSObject
@property (nonatomic, strong) SCSocket *socket;
@property NSString *cid;

@property (nonatomic, strong) SCChannel *_Nullable channel;
@property (nonatomic, strong) NSString *_Nullable eventName;
@property (nonatomic, strong) _Nullable id data;

@property (nonatomic, copy) _Nullable SCMessageSentHandler onSuccess;
@property (nonatomic, copy) _Nullable SCMessageSentHandler onFail;


@property (nonatomic, strong) NSDictionary *event;

- (instancetype)initWithSocket:(SCSocket *)socket andEventName:(nullable NSString *)eventName andData:(nullable id)data;

- (NSString *)send;

- (NSString *)sendToChannel:(SCChannel *_Nonnull)channel;

- (BOOL)isEqual:(nonnull SCMessage *)object;


@end
