//
//  APIService.m
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import "APIService.h"
#import "NetworkManager.h"

@implementation APIService

+ (void)kaLoginWithLicense:(NSString *)license
                  deviceId:(NSString *)deviceId
                completion:(LoginCompletion)completion {

    NSDictionary *params = @{
        @"kaPwd": license ?: @"",
        @"deviceId": deviceId ?: @"",
        @"platformType": @"iOS"
    };

    [NetworkManager postWithPath:@"/api/consumer/user/kaLogin" params:params completion:^(NSDictionary * _Nullable responseDict, NSError * _Nullable error) {
        if (error) {
            if (completion) {
                completion(NO, nil, error.localizedDescription);
            }
            return;
        }

        // 解析响应
        BOOL success = [responseDict[@"success"] boolValue];
        NSInteger code = [responseDict[@"code"] integerValue];
        NSString *msg = responseDict[@"msg"];

        if (code == 200 && success) {
            // 登录成功，保存 token
            NSDictionary *data = responseDict[@"data"];
            NSString *token = data[@"token"];
            if (token) {
                [NetworkManager setToken:token];
            }

            if (completion) {
                completion(YES, data, msg);
            }
        } else {
            if (completion) {
                completion(NO, nil, msg ?: @"登录失败");
            }
        }
    }];
}

@end
