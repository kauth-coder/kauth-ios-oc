//
//  NetworkManager.m
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import "NetworkManager.h"
#import "Config.h"

static NSString *g_token = nil;

@implementation NetworkManager

+ (NSString *)token {
    return g_token;
}

+ (void)setToken:(NSString *)token {
    g_token = [token copy];
}

+ (void)clearToken {
    g_token = nil;
}

+ (void)postWithPath:(NSString *)path
              params:(NSDictionary *)params
          completion:(NetworkCompletion)completion {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", Config.apiDomain, path]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30;

    // 设置固定请求头
    [request setValue:@"close" forHTTPHeaderField:@"ka-sign-type"];
    [request setValue:@"cloud" forHTTPHeaderField:@"ka-encryption"];
    [request setValue:Config.programId forHTTPHeaderField:@"Program-Id"];

    // 如果有 token，设置到请求头
    if (g_token) {
        [request setValue:g_token forHTTPHeaderField:@"accesstoken"];
    }

    // 设置 Content-Type 和 body
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    if (params) {
        NSError *jsonError;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&jsonError];
        if (jsonError) {
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        request.HTTPBody = bodyData;
    }

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (completion) {
                    completion(nil, error);
                }
                return;
            }

            if (!data) {
                NSError *noDataError = [NSError errorWithDomain:@"NetworkManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"无响应数据"}];
                if (completion) {
                    completion(nil, noDataError);
                }
                return;
            }

            NSError *parseError;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            if (parseError) {
                if (completion) {
                    completion(nil, parseError);
                }
                return;
            }

            if (completion) {
                completion(responseDict, nil);
            }
        });
    }];

    [task resume];
}

@end
