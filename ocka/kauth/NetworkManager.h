//
//  NetworkManager.h
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^NetworkCompletion)(NSDictionary * _Nullable responseDict, NSError * _Nullable error);

@interface NetworkManager : NSObject

/// 当前保存的 token
@property (class, nonatomic, copy, readonly) NSString * _Nullable token;

/// 当前登录用户信息
@property (class, nonatomic, copy, readonly) NSDictionary * _Nullable userInfo;

/// 心跳间隔（毫秒）
@property (class, nonatomic, assign, readonly) NSInteger pongInterval;

+ (void)setToken:(NSString *)token;
+ (void)setUserInfo:(NSDictionary *)info;
+ (void)clearSession;

/// POST 请求（带加密/签名/验签/解密）
+ (void)postWithPath:(NSString *)path
              params:(NSDictionary * _Nullable)params
          completion:(NetworkCompletion)completion;

@end

NS_ASSUME_NONNULL_END
