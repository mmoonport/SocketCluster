//
//  handlers.h
//  SocketCluster
//
//  Created by Matthew Moon on 11/25/18.
//

#ifndef handlers_h
#define handlers_h
typedef void(^SCDataHandler)(_Nullable id error, _Nullable id response);
typedef void(^SCMessageSentHandler)(_Nullable id message, _Nullable id response);
typedef void(^SCMessageSendFailHandler)(_Nullable id message, _Nullable id response);
typedef void(^SCChannelSubscribeHandler)(_Nullable id response);
typedef void(^SCChannelKickOutHandler)(_Nullable id response);
typedef void(^SCChannelUnsubscribeHandler)(void);
typedef void(^SCChannelSubscribeFailHandler)(NSError *_Nullable error, _Nullable id response);

#endif /* handlers_h */
