//
//  Config.m
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import "Config.h"

@implementation Config

/// ==========================================
///  ⚠️ 客户配置区 - 请填写以下必填项
/// ==========================================
/// API 域名
static NSString * const kApiDomain = @"https://kauth.cn";
/// 程序ID
static NSString * const kProgramId = @"1959821336266936321";
/// ==========================================

+ (NSString *)apiDomain {
    return kApiDomain;
}

+ (NSString *)programId {
    return kProgramId;
}

+ (BOOL)validateConfiguration {
    NSString *domain = self.apiDomain;
    NSString *programId = self.programId;

    // 检查是否为空或仅包含空白字符
    domain = [domain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    programId = [programId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (domain.length == 0 || programId.length == 0) {
        NSLog(@"❌ 配置不完整，请检查 Config.m 中的 kApiDomain 和 kProgramId 是否已填写");
        return NO;
    }
    return YES;
}

@end
