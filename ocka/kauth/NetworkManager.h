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

/// 当前保存的 token（内存中，不持久化）
@property (class, nonatomic, copy, readonly) NSString * _Nullable token;

/// 设置 token（登录成功后调用）
+ (void)setToken:(NSString *)token;

/// 清除 token（登出时调用）
+ (void)clearToken;

/// POST 请求
/// @param path 接口路径，如 "/api/consumer/user/kaLogin"
/// @param params 入参字典
/// @param completion 完成回调
+ (void)postWithPath:(NSString *)path
              params:(NSDictionary * _Nullable)params
          completion:(NetworkCompletion)completion;

@end

NS_ASSUME_NONNULL_END
