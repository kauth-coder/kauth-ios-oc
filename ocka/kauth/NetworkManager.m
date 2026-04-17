//
//  NetworkManager.m
//  ocka
//
//  Created by kauth-coder on 2026/3/31.
//

#import "NetworkManager.h"
#import "Config.h"
#import "CryptoUtil.h"
#import "SignTools.h"

/// 响应时间戳容忍窗口（毫秒）
static const long long kTimestampRecent = 120000;

static NSString *g_token = nil;
static NSDictionary *g_userInfo = nil;
static NSInteger g_pongInterval = 60000;

@implementation NetworkManager

#pragma mark - Session

+ (NSString *)token { return g_token; }
+ (NSDictionary *)userInfo { return g_userInfo; }
+ (NSInteger)pongInterval { return g_pongInterval; }

+ (void)setToken:(NSString *)token { g_token = [token copy]; }

+ (void)setUserInfo:(NSDictionary *)info {
    g_userInfo = [info copy];
    id interval = info[@"pongInterval"];
    if (interval) g_pongInterval = [interval integerValue];
}

+ (void)clearSession {
    g_token = nil;
    g_userInfo = nil;
}

#pragma mark - POST 请求

+ (void)postWithPath:(NSString *)path
              params:(NSDictionary *)params
          completion:(NetworkCompletion)completion {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", Config.apiDomain, path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    // ============ 请求加密与签名 ============

    NSString *plainBody = nil;
    NSString *encryptedBody = nil;
    if (params) {
        NSError *jsonError;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&jsonError];
        if (jsonError) {
            if (completion) completion(nil, jsonError);
            return;
        }
        plainBody = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        encryptedBody = [CryptoUtil aesEncrypt:plainBody secret:Config.programSecret];
    }

    long long kaTime = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *kaNonce = [NSString stringWithFormat:@"%lld_%@", kaTime, [[NSUUID UUID] UUIDString]];

    NSString *sign = [SignTools signWithURL:path body:plainBody nonce:kaNonce time:kaTime publicKey:Config.merchantPublicKey];
    if (!sign) {
        if (completion) {
            NSError *signError = [NSError errorWithDomain:@"KauthSDK" code:-100
                                                userInfo:@{NSLocalizedDescriptionKey: @"客户端签名生成失败"}];
            completion(nil, signError);
        }
        return;
    }

    [request setValue:Config.programId forHTTPHeaderField:@"Program-Id"];
    [request setValue:kaNonce forHTTPHeaderField:@"ka-nonce"];
    [request setValue:[NSString stringWithFormat:@"%lld", kaTime] forHTTPHeaderField:@"ka-time"];
    [request setValue:@"RSA" forHTTPHeaderField:@"ka-sign-type"];
    [request setValue:sign forHTTPHeaderField:@"ka-sign"];

    if (g_token) {
        [request setValue:g_token forHTTPHeaderField:@"accesstoken"];
    }

    if (encryptedBody) {
        request.HTTPBody = [encryptedBody dataUsingEncoding:NSUTF8StringEncoding];
    }

    NSLog(@"[KAuth] >> POST %@ (token=%@)", path, g_token ? @"yes" : @"no");

    // ============ 发送请求 ============

    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"[KAuth] << %@ 网络错误: %@", path, error.localizedDescription);
                if (completion) completion(nil, error);
                return;
            }
            if (!data) {
                if (completion) {
                    NSError *noData = [NSError errorWithDomain:@"KauthSDK" code:-1
                                                      userInfo:@{NSLocalizedDescriptionKey: @"无响应数据"}];
                    completion(nil, noData);
                }
                return;
            }

            NSError *parseError;
            NSDictionary *rawDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            if (parseError || ![rawDict isKindOfClass:[NSDictionary class]]) {
                if (completion) completion(nil, parseError ?: [NSError errorWithDomain:@"KauthSDK" code:-2
                                                                              userInfo:@{NSLocalizedDescriptionKey: @"响应 JSON 解析失败"}]);
                return;
            }

            // 如果业务不成功，直接返回（不需要验签/解密）
            BOOL success = [rawDict[@"success"] boolValue];
            if (!success) {
                NSLog(@"[KAuth] << %@ 业务失败: code=%@, msg=%@", path, rawDict[@"code"], rawDict[@"msg"]);
                if (completion) completion(rawDict, nil);
                return;
            }

            // ============ 响应验签 & 解密 ============
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            NSString *respNonce   = [httpResp valueForHTTPHeaderField:@"ka-nonce"];
            NSString *respTimeStr = [httpResp valueForHTTPHeaderField:@"ka-time"];
            NSString *respSign    = [httpResp valueForHTTPHeaderField:@"ka-sign"];

            if (!respNonce.length || !respTimeStr.length || !respSign.length) {
                if (completion) {
                    NSError *headerErr = [NSError errorWithDomain:@"KauthSDK" code:-3
                                                        userInfo:@{NSLocalizedDescriptionKey: @"服务器响应头签名信息不完整"}];
                    completion(nil, headerErr);
                }
                return;
            }

            long long respTime = [respTimeStr longLongValue];
            long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
            if (now - respTime >= kTimestampRecent) {
                if (completion) {
                    NSError *timeErr = [NSError errorWithDomain:@"KauthSDK" code:-4
                                                      userInfo:@{NSLocalizedDescriptionKey: @"请求超时（响应时间戳过期）"}];
                    completion(nil, timeErr);
                }
                return;
            }

            // 解密响应 data
            NSString *decryptedBody = nil;
            NSString *encData = rawDict[@"data"];
            if ([encData isKindOfClass:[NSString class]] && encData.length > 0) {
                decryptedBody = [CryptoUtil aesDecrypt:encData secret:Config.programSecret];
                if (!decryptedBody) {
                    if (completion) {
                        NSError *decErr = [NSError errorWithDomain:@"KauthSDK" code:-5
                                                          userInfo:@{NSLocalizedDescriptionKey: @"响应体解密失败"}];
                        completion(nil, decErr);
                    }
                    return;
                }
            }

            // 验证服务器签名
            BOOL verified = [SignTools verifyResponseSignWithURL:path
                                                           body:decryptedBody
                                                          nonce:respNonce
                                                           time:respTime
                                                           sign:respSign
                                                      publicKey:Config.merchantPublicKey];
            if (!verified) {
                if (completion) {
                    NSError *signErr = [NSError errorWithDomain:@"KauthSDK" code:-6
                                                      userInfo:@{NSLocalizedDescriptionKey: @"服务器签名验证失败"}];
                    completion(nil, signErr);
                }
                return;
            }

            // ============ 构造最终响应字典 ============
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            result[@"msg"]      = rawDict[@"msg"] ?: @"";
            result[@"code"]     = rawDict[@"code"] ?: @0;
            result[@"traceId"]  = rawDict[@"traceId"] ?: @"";
            result[@"elapse"]   = rawDict[@"elapse"] ?: @"";
            result[@"respTime"] = rawDict[@"respTime"] ?: @"";
            result[@"success"]  = @([rawDict[@"code"] integerValue] == 200);

            if (decryptedBody) {
                NSData *bodyData = [decryptedBody dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];
                if (dataDict) {
                    result[@"data"] = dataDict;
                }
            }

            NSLog(@"[KAuth] << %@ 成功", path);
            if (completion) completion([result copy], nil);
        });
    }];

    [task resume];
}

@end
