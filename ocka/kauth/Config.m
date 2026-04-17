//
//  Config.m
//  ocka
//
//  Created by kauth-coder on 2026/3/31.
//

#import "Config.h"

@implementation Config

/// ==========================================
///  ⚠️ 客户配置区 - 请填写以下必填项
/// ==========================================
/// API 域名  接入点: https://api.kauth.cn
static NSString * const kApiDomain = @"https://api.kauth.cn";
/// 程序ID    程序管理 -> 程序列表 -> 程序 ID
static NSString * const kProgramId = @"1959821336266936321";
/// 程序密钥   程序管理 -> 程序列表 -> 程序密钥
static NSString * const kProgramSecret = @"F77VzI7UWAElpWrz";
/// 商户 RSA 公钥. 系统设置 -> 密钥配置 -> RSA公钥 (PKCS#8)
static NSString * const kMerchantPublicKey = @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCIpy3ae27yDJOUd5rW/S6tUbAmt/AqJm+VPonT9WJn5VME4FkYJUwdBmIWpzANVQmU+7CA3wv5eVFIOW0xMv9EyoFWDRR24Jt/hgDsZQtUPMaZPivKWxx2S4n4SJWWrGdIRkdC3+fmxrEri1qYicq8PO7mDIrwPR2I0USoKKOFMwIDAQAB";
/// ==========================================

+ (NSString *)apiDomain {
    return kApiDomain;
}

+ (NSString *)programId {
    return kProgramId;
}

+ (NSString *)programSecret {
    return kProgramSecret;
}

+ (NSString *)merchantPublicKey {
    return kMerchantPublicKey;
}

+ (BOOL)validateConfiguration {
    NSArray *fields = @[self.apiDomain, self.programId, self.programSecret, self.merchantPublicKey];
    for (NSString *field in fields) {
        NSString *trimmed = [field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) {
            NSLog(@"❌ 配置不完整，请检查 Config.m 中的必填项是否已填写");
            return NO;
        }
    }
    return YES;
}

@end
