//
//  SCMessage.h
//  
//
//  Created by Anatoliy Popov on 20.12.15.
//  Copyright © 2015 Anatoliy Popov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "handlers.h"
@class SCSocket;
@class SCChannel;

@interface SCMessage : NSObject
@property (nonatomic, weak) SCSocket *socket;
@property NSString *cid;

@property (nonatomic, weak) SCChannel *_Nullable channel;
@property (nonatomic, strong) NSString *_Nullable eventName;
@property (nonatomic, strong) _Nullable id data;

@property (nonatomic, strong) SCMessageSentHandler onSuccess;
@property (nonatomic, strong) SCMessageSentHandler onFail;


@property (nonatomic, strong) NSDictionary *event;

- (instancetype)initWithSocket:(SCSocket *)socket andEventName:(nullable NSString *)eventName andData:(nullable id)data;

- (NSString *)send;

- (NSString *)sendToChannel:(SCChannel *_Nonnull)channel;

- (BOOL)isEqual:(nonnull SCMessage *)object;


@end
