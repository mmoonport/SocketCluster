//
// Created by Matthew Moon on 11/23/18.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SocketCluster)
- (NSData *)toJSON:(NSError *)error;

- (NSString *)toJSONString;
@end