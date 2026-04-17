//
//  APIService.m
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import "APIService.h"
#import "NetworkManager.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

/// 通用响应解析
static inline void KAHandleResponse(NSDictionary *responseDict, NSError *error, APICompletion completion) {
    if (!completion) return;
    if (error) {
        completion(NO, nil, error.localizedDescription);
        return;
    }
    BOOL success = [responseDict[@"success"] boolValue];
    NSInteger code = [responseDict[@"code"] integerValue];
    NSString *msg = responseDict[@"msg"];
    NSDictionary *data = responseDict[@"data"];
    if (code == 200 && success) {
        completion(YES, data, msg);
    } else {
        completion(NO, data, msg ?: @"请求失败");
    }
}

static dispatch_source_t g_pongTimer = nil;

@implementation APIService

#pragma mark - 设备ID（Keychain 持久化）

static NSString *const kKeychainDeviceIdKey = @"cn.kauth.ocka.deviceId";

+ (NSString *)getDeviceId {
    // 1. 先从 Keychain 读取
    NSString *stored = [self _readDeviceIdFromKeychain];
    if (stored.length > 0) {
        return stored;
    }
    // 2. 首次获取：用 identifierForVendor，存入 Keychain
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: [[NSUUID UUID] UUIDString];
    [self _saveDeviceIdToKeychain:deviceId];
    return deviceId;
}

+ (NSString *)_readDeviceIdFromKeychain {
    NSDictionary *query = @{
        (__bridge id)kSecClass:            (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:      kKeychainDeviceIdKey,
        (__bridge id)kSecAttrAccount:      kKeychainDeviceIdKey,
        (__bridge id)kSecReturnData:       @YES,
        (__bridge id)kSecMatchLimit:       (__bridge id)kSecMatchLimitOne,
    };
    CFTypeRef dataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataRef);
    if (status == errSecSuccess && dataRef) {
        NSString *result = [[NSString alloc] initWithData:(__bridge_transfer NSData *)dataRef encoding:NSUTF8StringEncoding];
        return result;
    }
    return nil;
}

+ (void)_saveDeviceIdToKeychain:(NSString *)deviceId {
    NSData *data = [deviceId dataUsingEncoding:NSUTF8StringEncoding];
    // 先删除旧值（忽略结果）
    NSDictionary *deleteQuery = @{
        (__bridge id)kSecClass:       (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeychainDeviceIdKey,
        (__bridge id)kSecAttrAccount: kKeychainDeviceIdKey,
    };
    SecItemDelete((__bridge CFDictionaryRef)deleteQuery);
    // 写入新值
    NSDictionary *addQuery = @{
        (__bridge id)kSecClass:           (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:     kKeychainDeviceIdKey,
        (__bridge id)kSecAttrAccount:     kKeychainDeviceIdKey,
        (__bridge id)kSecValueData:       data,
        (__bridge id)kSecAttrAccessible:  (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
    };
    SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
}

#pragma mark - 用户认证

+ (void)kaLoginWithLicense:(NSString *)license
                  deviceId:(NSString *)deviceId
                completion:(APICompletion)completion {

    NSDictionary *params = @{
        @"kaPwd": license ?: @"",
        @"deviceId": deviceId ?: @"",
        @"platformType": @"iOS"
    };

    [NetworkManager postWithPath:@"/api/consumer/user/kaLogin" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(NO, nil, error.localizedDescription);
            return;
        }
        BOOL success = [responseDict[@"success"] boolValue];
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = responseDict[@"msg"];
        NSDictionary *data = responseDict[@"data"];
        if (code == 200 && success) {
            NSString *token = data[@"token"];
            if (token) [NetworkManager setToken:token];
            [NetworkManager setUserInfo:data ?: @{}];
            if (completion) completion(YES, data, msg);
        } else {
            if (completion) completion(NO, data, msg ?: @"登录失败");
        }
    }];
}

+ (void)pwdLoginWithName:(NSString *)loginName
                password:(NSString *)password
                deviceId:(NSString *)deviceId
             captchaCode:(nullable NSString *)captchaCode
             captchaUuid:(nullable NSString *)captchaUuid
              completion:(APICompletion)completion {

    NSMutableDictionary *params = [@{
        @"loginName": loginName ?: @"",
        @"password": password ?: @"",
        @"deviceId": deviceId ?: @"",
        @"platformType": @"iOS"
    } mutableCopy];
    if (captchaCode) params[@"captchaCode"] = captchaCode;
    if (captchaUuid) params[@"captchaUuid"] = captchaUuid;

    [NetworkManager postWithPath:@"/api/consumer/user/pwdLogin" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(NO, nil, error.localizedDescription);
            return;
        }
        BOOL success = [responseDict[@"success"] boolValue];
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = responseDict[@"msg"];
        NSDictionary *data = responseDict[@"data"];
        if (code == 200 && success) {
            NSString *token = data[@"token"];
            if (token) [NetworkManager setToken:token];
            [NetworkManager setUserInfo:data ?: @{}];
            if (completion) completion(YES, data, msg);
        } else {
            if (completion) completion(NO, data, msg ?: @"登录失败");
        }
    }];
}

+ (void)trialLoginWithDeviceId:(NSString *)deviceId
                    completion:(APICompletion)completion {

    NSDictionary *params = @{
        @"deviceId": deviceId ?: @"",
        @"platformType": @"iOS"
    };

    [NetworkManager postWithPath:@"/api/consumer/user/trialLogin" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(NO, nil, error.localizedDescription);
            return;
        }
        BOOL success = [responseDict[@"success"] boolValue];
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = responseDict[@"msg"];
        NSDictionary *data = responseDict[@"data"];
        if (code == 200 && success) {
            NSString *token = data[@"token"];
            if (token) [NetworkManager setToken:token];
            [NetworkManager setUserInfo:data ?: @{}];
            if (completion) completion(YES, data, msg);
        } else {
            if (completion) completion(NO, data, msg ?: @"登录失败");
        }
    }];
}

+ (void)loginOutWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/user/loginOut" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        [self stopAutoPong];
        [NetworkManager clearSession];
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)registerWithLoginName:(NSString *)loginName
                     password:(NSString *)password
                   kaPassword:(nullable NSString *)kaPassword
                     nickName:(nullable NSString *)nickName
                     deviceId:(NSString *)deviceId
                  captchaCode:(nullable NSString *)captchaCode
                  captchaUuid:(nullable NSString *)captchaUuid
                   completion:(APICompletion)completion {

    NSMutableDictionary *params = [@{
        @"loginName": loginName ?: @"",
        @"password": password ?: @"",
        @"deviceId": deviceId ?: @""
    } mutableCopy];
    if (kaPassword) params[@"kaPassword"] = kaPassword;
    if (nickName) params[@"nickName"] = nickName;
    if (captchaCode) params[@"captchaCode"] = captchaCode;
    if (captchaUuid) params[@"captchaUuid"] = captchaUuid;

    [NetworkManager postWithPath:@"/api/consumer/user/register" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getCaptchaWithUuid:(NSString *)uuid
                completion:(APICompletion)completion {
    NSDictionary *params = @{@"uuid": uuid ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/user/getCaptcha" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getUserInfoWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/user/getUserInfo" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)pongWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/user/pong" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

/// 内部心跳方法，区分网络错误和业务错误
+ (void)_internalPongWithCompletion:(void(^)(BOOL success, BOOL isNetworkError, NSString *message))completion {
    [NetworkManager postWithPath:@"/api/consumer/user/pong" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[KAuth] 心跳网络错误: %@", error.localizedDescription);
            if (completion) completion(NO, YES, error.localizedDescription);
            return;
        }
        BOOL success = [responseDict[@"success"] boolValue];
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = responseDict[@"msg"];
        if (code == 200 && success) {
            NSLog(@"[KAuth] 心跳成功");
            if (completion) completion(YES, NO, msg ?: @"心跳正常");
        } else {
            NSLog(@"[KAuth] 心跳业务错误: code=%ld, msg=%@", (long)code, msg);
            if (completion) completion(NO, NO, msg ?: @"心跳失败");
        }
    }];
}

+ (void)rechargeWithLoginName:(NSString *)loginName
                   kaPassword:(NSString *)kaPassword
                     deviceId:(NSString *)deviceId
                  captchaCode:(nullable NSString *)captchaCode
                  captchaUuid:(nullable NSString *)captchaUuid
                   completion:(APICompletion)completion {

    NSMutableDictionary *params = [@{
        @"loginName": loginName ?: @"",
        @"kaPassword": kaPassword ?: @"",
        @"deviceId": deviceId ?: @""
    } mutableCopy];
    if (captchaCode) params[@"captchaCode"] = captchaCode;
    if (captchaUuid) params[@"captchaUuid"] = captchaUuid;

    [NetworkManager postWithPath:@"/api/consumer/user/recharge" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)rechargeKaWithCardPwd:(NSString *)cardPwd
              rechargeCardPwd:(NSString *)rechargeCardPwd
                   completion:(APICompletion)completion {
    NSDictionary *params = @{
        @"cardPwd": cardPwd ?: @"",
        @"rechargeCardPwd": rechargeCardPwd ?: @""
    };
    [NetworkManager postWithPath:@"/api/consumer/user/rechargeKa" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)changePasswordWithLoginName:(NSString *)loginName
                        oldPassword:(NSString *)oldPassword
                        newPassword:(NSString *)newPassword
                    confirmPassword:(NSString *)confirmPassword
                        captchaCode:(nullable NSString *)captchaCode
                        captchaUuid:(nullable NSString *)captchaUuid
                         completion:(APICompletion)completion {

    NSMutableDictionary *params = [@{
        @"loginName": loginName ?: @"",
        @"oldPassword": oldPassword ?: @"",
        @"newPassword": newPassword ?: @"",
        @"confirmPassword": confirmPassword ?: @""
    } mutableCopy];
    if (captchaCode) params[@"captchaCode"] = captchaCode;
    if (captchaUuid) params[@"captchaUuid"] = captchaUuid;

    [NetworkManager postWithPath:@"/api/consumer/user/changePassword" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)unbindDeviceWithLoginName:(NSString *)loginName
                         password:(NSString *)password
                         deviceId:(NSString *)deviceId
                      captchaCode:(nullable NSString *)captchaCode
                      captchaUuid:(nullable NSString *)captchaUuid
                       completion:(APICompletion)completion {

    NSMutableDictionary *params = [@{
        @"loginName": loginName ?: @"",
        @"password": password ?: @"",
        @"deviceId": deviceId ?: @""
    } mutableCopy];
    if (captchaCode) params[@"captchaCode"] = captchaCode;
    if (captchaUuid) params[@"captchaUuid"] = captchaUuid;

    [NetworkManager postWithPath:@"/api/consumer/user/unbindDevice" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)unbindDeviceWithKaPwd:(NSString *)kaPwd
                     deviceId:(NSString *)deviceId
                   completion:(APICompletion)completion {
    NSDictionary *params = @{
        @"kaPwd": kaPwd ?: @"",
        @"deviceId": deviceId ?: @""
    };
    [NetworkManager postWithPath:@"/api/consumer/user/unbindDeviceKaPwd" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)cardUnBindDeviceWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/device/cardUnBindDevice" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

#pragma mark - 程序管理

+ (void)getProgramDetailWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/program/detail" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getServerTimeWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/program/serverTime" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

#pragma mark - 自定义配置

+ (void)updateUserConfig:(NSString *)config completion:(APICompletion)completion {
    NSDictionary *params = @{@"config": config ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/custom/config/updateUserConfig" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getUserConfigWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/custom/config/getUserConfig" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)updateKaConfig:(NSString *)config completion:(APICompletion)completion {
    NSDictionary *params = @{@"config": config ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/custom/config/updateKaConfig" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getKaConfigWithCompletion:(APICompletion)completion {
    [NetworkManager postWithPath:@"/api/consumer/custom/config/getKaConfig" params:nil completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

#pragma mark - 远程控制

+ (void)getRemoteVarWithKey:(NSString *)key completion:(APICompletion)completion {
    NSDictionary *params = @{@"key": key ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/remote/getRemoteVar" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getRemoteDataWithKey:(NSString *)key completion:(APICompletion)completion {
    NSDictionary *params = @{@"key": key ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/remote/getRemoteData" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)addRemoteDataWithKey:(NSString *)key value:(NSString *)value completion:(APICompletion)completion {
    NSDictionary *params = @{@"key": key ?: @"", @"value": value ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/remote/addRemoteData" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)updateRemoteDataWithKey:(NSString *)key value:(NSString *)value completion:(APICompletion)completion {
    NSDictionary *params = @{@"key": key ?: @"", @"value": value ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/remote/updateRemoteData" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)deleteRemoteDataWithKey:(NSString *)key completion:(APICompletion)completion {
    NSDictionary *params = @{@"key": key ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/remote/deleteRemoteData" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)callFunctionWithName:(NSString *)functionName
                      params:(nullable NSArray<NSDictionary *> *)functionParams
                  completion:(APICompletion)completion {
    NSMutableDictionary *p = [@{@"functionName": functionName ?: @""} mutableCopy];
    if (functionParams) p[@"functionParams"] = functionParams;
    [NetworkManager postWithPath:@"/api/consumer/remote/callFunction" params:p completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getNewestScriptWithName:(NSString *)scriptName completion:(APICompletion)completion {
    NSDictionary *params = @{@"scriptName": scriptName ?: @""};
    [NetworkManager postWithPath:@"/api/consumer/remote/getNewestScript" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

+ (void)getScriptDownloadWithName:(NSString *)scriptName
                    versionNumber:(nullable NSString *)versionNumber
                       completion:(APICompletion)completion {
    NSMutableDictionary *params = [@{@"scriptName": scriptName ?: @""} mutableCopy];
    if (versionNumber) params[@"versionNumber"] = versionNumber;
    [NetworkManager postWithPath:@"/api/consumer/remote/getScriptDownload" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        KAHandleResponse(responseDict, error, completion);
    }];
}

#pragma mark - 自动心跳

+ (void)startAutoPongWithMaxFail:(NSInteger)maxConnFail
                          onPong:(void(^)(BOOL success, NSString *message))onPong
                          onFail:(void(^)(NSString *reason, NSString *message))onFail {
    [self stopAutoPong];

    __block NSInteger currentNetFail = 0;
    NSTimeInterval interval = NetworkManager.pongInterval / 1000.0;
    if (interval < 10) interval = 60;
    NSLog(@"[KAuth] 启动自动心跳，间隔=%.0f秒，最大网络失败=%ld", interval, (long)maxConnFail);

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    g_pongTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    // 首次 5 秒后触发
    dispatch_source_set_timer(g_pongTimer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                              (uint64_t)(interval * NSEC_PER_SEC), (uint64_t)(1 * NSEC_PER_SEC));

    dispatch_source_set_event_handler(g_pongTimer, ^{
        NSLog(@"[KAuth] 心跳定时器触发");

        if (!NetworkManager.userInfo) {
            NSLog(@"[KAuth] userInfo 为空，登录已失效");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (onPong) onPong(NO, @"登录已失效");
                if (onFail) onFail(@"INVALID_LOGIN", @"登录已失效，请尝试重新登录！");
            });
            [self stopAutoPong];
            return;
        }

        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [self _internalPongWithCompletion:^(BOOL success, BOOL isNetworkError, NSString *message) {
            if (success) {
                currentNetFail = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (onPong) onPong(YES, @"心跳正常");
                });
            } else if (isNetworkError) {
                currentNetFail++;
                NSLog(@"[KAuth] 网络失败 %ld/%ld: %@", (long)currentNetFail, (long)maxConnFail, message);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (onPong) onPong(NO, [NSString stringWithFormat:@"网络异常(%ld/%ld)", (long)currentNetFail, (long)maxConnFail]);
                });
                if (currentNetFail >= maxConnFail) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (onFail) onFail(@"MAXFAIL_CONNECTION", @"心跳网络失败已达最大次数");
                    });
                    [self stopAutoPong];
                }
            } else {
                // 业务错误（冻结/过期/被踢）：立即停止
                NSLog(@"[KAuth] 业务错误，立即停止心跳: %@", message);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (onPong) onPong(NO, message);
                    if (onFail) onFail(@"BUSINESS_ERROR", message ?: @"心跳业务错误");
                });
                [self stopAutoPong];
            }
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    });

    dispatch_resume(g_pongTimer);
    NSLog(@"[KAuth] 自动心跳已启动");
}

+ (void)stopAutoPong {
    if (g_pongTimer) {
        dispatch_source_cancel(g_pongTimer);
        g_pongTimer = nil;
    }
}

@end
