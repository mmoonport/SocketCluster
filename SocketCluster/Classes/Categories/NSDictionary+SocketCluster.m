//
// Created by Matthew Moon on 11/23/18.
//

#import "NSDictionary+SocketCluster.h"


@implementation NSDictionary (SocketCluster)
- (NSData *)toJSON:(NSError *)error
{
    return [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:&error];
}

- (NSString *)toJSONString
{
    NSError *error;
    NSData *jsonData = [self toJSON:error];
    if (jsonData) {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return @"";
}
@end