//
//  SignTools.h
//  ocka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignTools : NSObject

/// 生成请求签名
+ (nullable NSString *)signWithURL:(NSString *)url
                              body:(nullable NSString *)body
                             nonce:(NSString *)nonce
                              time:(long long)time
                         publicKey:(NSString *)publicKey;

/// 验证服务器响应签名
+ (BOOL)verifyResponseSignWithURL:(NSString *)url
                             body:(nullable NSString *)body
                            nonce:(NSString *)nonce
                             time:(long long)time
                             sign:(NSString *)sign
                        publicKey:(NSString *)publicKey;

@end

NS_ASSUME_NONNULL_END
