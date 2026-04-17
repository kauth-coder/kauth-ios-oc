//
//  APIService.h
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^APICompletion)(BOOL success, NSDictionary * _Nullable data, NSString * _Nullable message);

@interface APIService : NSObject

#pragma mark - 设备ID

/// 获取设备唯一ID（首次生成后持久化到 Keychain，卸载重装也不变）
+ (NSString *)getDeviceId;

#pragma mark - 用户认证

/// 卡密登录
+ (void)kaLoginWithLicense:(NSString *)license
                  deviceId:(NSString *)deviceId
                completion:(APICompletion)completion;

/// 账号密码登录
+ (void)pwdLoginWithName:(NSString *)loginName
                password:(NSString *)password
                deviceId:(NSString *)deviceId
             captchaCode:(nullable NSString *)captchaCode
             captchaUuid:(nullable NSString *)captchaUuid
              completion:(APICompletion)completion;

/// 试用登录
+ (void)trialLoginWithDeviceId:(NSString *)deviceId
                    completion:(APICompletion)completion;

/// 退出登录
+ (void)loginOutWithCompletion:(APICompletion)completion;

/// 用户注册
+ (void)registerWithLoginName:(NSString *)loginName
                     password:(NSString *)password
                   kaPassword:(nullable NSString *)kaPassword
                     nickName:(nullable NSString *)nickName
                     deviceId:(NSString *)deviceId
                  captchaCode:(nullable NSString *)captchaCode
                  captchaUuid:(nullable NSString *)captchaUuid
                   completion:(APICompletion)completion;

/// 获取图形验证码
+ (void)getCaptchaWithUuid:(NSString *)uuid
                completion:(APICompletion)completion;

/// 获取用户信息
+ (void)getUserInfoWithCompletion:(APICompletion)completion;

/// 心跳
+ (void)pongWithCompletion:(APICompletion)completion;

/// 账户充值
+ (void)rechargeWithLoginName:(NSString *)loginName
                   kaPassword:(NSString *)kaPassword
                     deviceId:(NSString *)deviceId
                  captchaCode:(nullable NSString *)captchaCode
                  captchaUuid:(nullable NSString *)captchaUuid
                   completion:(APICompletion)completion;

/// 以卡充卡
+ (void)rechargeKaWithCardPwd:(NSString *)cardPwd
              rechargeCardPwd:(NSString *)rechargeCardPwd
                   completion:(APICompletion)completion;

/// 修改密码
+ (void)changePasswordWithLoginName:(NSString *)loginName
                        oldPassword:(NSString *)oldPassword
                        newPassword:(NSString *)newPassword
                    confirmPassword:(NSString *)confirmPassword
                        captchaCode:(nullable NSString *)captchaCode
                        captchaUuid:(nullable NSString *)captchaUuid
                         completion:(APICompletion)completion;

/// 账密方式解绑设备
+ (void)unbindDeviceWithLoginName:(NSString *)loginName
                         password:(NSString *)password
                         deviceId:(NSString *)deviceId
                      captchaCode:(nullable NSString *)captchaCode
                      captchaUuid:(nullable NSString *)captchaUuid
                       completion:(APICompletion)completion;

/// 卡密方式解绑设备
+ (void)unbindDeviceWithKaPwd:(NSString *)kaPwd
                     deviceId:(NSString *)deviceId
                   completion:(APICompletion)completion;

/// 卡密解绑设备（已登录状态）
+ (void)cardUnBindDeviceWithCompletion:(APICompletion)completion;

#pragma mark - 程序管理

+ (void)getProgramDetailWithCompletion:(APICompletion)completion;
+ (void)getServerTimeWithCompletion:(APICompletion)completion;

#pragma mark - 自定义配置

+ (void)updateUserConfig:(NSString *)config completion:(APICompletion)completion;
+ (void)getUserConfigWithCompletion:(APICompletion)completion;
+ (void)updateKaConfig:(NSString *)config completion:(APICompletion)completion;
+ (void)getKaConfigWithCompletion:(APICompletion)completion;

#pragma mark - 远程控制

+ (void)getRemoteVarWithKey:(NSString *)key completion:(APICompletion)completion;
+ (void)getRemoteDataWithKey:(NSString *)key completion:(APICompletion)completion;
+ (void)addRemoteDataWithKey:(NSString *)key value:(NSString *)value completion:(APICompletion)completion;
+ (void)updateRemoteDataWithKey:(NSString *)key value:(NSString *)value completion:(APICompletion)completion;
+ (void)deleteRemoteDataWithKey:(NSString *)key completion:(APICompletion)completion;
+ (void)callFunctionWithName:(NSString *)functionName
                      params:(nullable NSArray<NSDictionary *> *)functionParams
                  completion:(APICompletion)completion;
+ (void)getNewestScriptWithName:(NSString *)scriptName completion:(APICompletion)completion;
+ (void)getScriptDownloadWithName:(NSString *)scriptName
                    versionNumber:(nullable NSString *)versionNumber
                       completion:(APICompletion)completion;

#pragma mark - 心跳管理

/// 启动自动心跳
+ (void)startAutoPongWithMaxFail:(NSInteger)maxConnFail
                          onPong:(void(^)(BOOL success, NSString *message))onPong
                          onFail:(void(^)(NSString *reason, NSString *message))onFail;

/// 停止自动心跳
+ (void)stopAutoPong;

@end

NS_ASSUME_NONNULL_END
