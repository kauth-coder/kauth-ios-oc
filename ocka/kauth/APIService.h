//
//  APIService.h
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LoginCompletion)(BOOL success, NSDictionary * _Nullable data, NSString * _Nullable message);

@interface APIService : NSObject

/// 登录
/// @param license 卡密
/// @param deviceId 设备ID
/// @param completion 完成回调
+ (void)kaLoginWithLicense:(NSString *)license
                  deviceId:(NSString *)deviceId
                completion:(LoginCompletion)completion;

@end

NS_ASSUME_NONNULL_END
