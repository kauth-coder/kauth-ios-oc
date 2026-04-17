//
//  Config.h
//  ocka
//
//  Created by songlongkuan on 2026/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 集中配置文件
/// 所有敏感配置都写在此文件，后续可用混淆工具加密字符串
@interface Config : NSObject

/// API 域名（必填）
@property (class, nonatomic, copy, readonly) NSString *apiDomain;

/// 程序ID（必填）
@property (class, nonatomic, copy, readonly) NSString *programId;

/// 程序密钥 / AES 加密密钥（必填）
@property (class, nonatomic, copy, readonly) NSString *programSecret;

/// 商户 RSA 公钥 Base64（必填）
@property (class, nonatomic, copy, readonly) NSString *merchantPublicKey;

/// 验证配置是否完整（必填项是否都已填写）
+ (BOOL)validateConfiguration;

@end

NS_ASSUME_NONNULL_END
