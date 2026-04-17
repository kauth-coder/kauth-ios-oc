//
//  SignTools.m
//  ocka
//

#import "SignTools.h"
#import "CryptoUtil.h"

@implementation SignTools

/// 构造签名模板
+ (NSString *)templateWithURL:(NSString *)url body:(nullable NSString *)body nonce:(NSString *)nonce time:(long long)time {
    return [NSString stringWithFormat:@"url:%@\nbody:%@\nnonce:%@\ntime:%lld",
            url ?: @"", body ?: @"", nonce ?: @"", time];
}

+ (nullable NSString *)signWithURL:(NSString *)url
                              body:(nullable NSString *)body
                             nonce:(NSString *)nonce
                              time:(long long)time
                         publicKey:(NSString *)publicKey {
    NSString *template = [self templateWithURL:url body:body nonce:nonce time:time];
    NSString *md5 = [CryptoUtil md5:template];
    return [CryptoUtil rsaEncryptByPublicKey:md5 publicKey:publicKey];
}

+ (BOOL)verifyResponseSignWithURL:(NSString *)url
                             body:(nullable NSString *)body
                            nonce:(NSString *)nonce
                             time:(long long)time
                             sign:(NSString *)sign
                        publicKey:(NSString *)publicKey {
    NSString *template = [self templateWithURL:url body:body nonce:nonce time:time];
    NSString *expectedMd5 = [CryptoUtil md5:template];
    NSString *decrypted = [CryptoUtil rsaDecryptByPublicKey:sign publicKey:publicKey];
    if (!decrypted) return NO;
    return [expectedMd5 isEqualToString:decrypted];
}

@end
