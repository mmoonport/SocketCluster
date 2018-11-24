//
// Created by Matthew Moon on 11/23/18.
//

#import <Foundation/Foundation.h>
@class SCChannel;
@class SCMessage;
@interface SCMessageHandler : NSObject
@property (nonatomic, strong) NSMutableArray<SCChannel *> *channels;
@property (nonatomic, strong) NSMutableArray<SCMessage *> *messages;

- (instancetype)initWithSocketCluster:(SCSocket *)socket;

- (void)didReceiveMessage:(NSString *)string;

- (void)didReceiveData:(NSData *)data;

- (SCMessage *)messageForID:(NSInteger)rid;

- (SCChannel *)channelForName:(NSString *)name;

- (SCChannel *)channelForID:(NSInteger)rid;

- (void)restoreConnection;
@end
