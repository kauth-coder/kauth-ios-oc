//
//  CryptoUtil.h
//  ocka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CryptoUtil : NSObject

/// MD5 哈希
+ (NSString *)md5:(NSString *)plainText;

/// AES/ECB/NoPadding 加密，返回 Base64
+ (nullable NSString *)aesEncrypt:(NSString *)content secret:(NSString *)secret;

/// AES/ECB/NoPadding 解密，输入 Base64
+ (nullable NSString *)aesDecrypt:(NSString *)content secret:(NSString *)secret;

/// RSA 公钥加密，返回 Base64
+ (nullable NSString *)rsaEncryptByPublicKey:(NSString *)plainText publicKey:(NSString *)publicKeyB64;

/// RSA 公钥解密（验签用：sig^e mod n），返回明文
+ (nullable NSString *)rsaDecryptByPublicKey:(NSString *)cipherText publicKey:(NSString *)publicKeyB64;

@end

NS_ASSUME_NONNULL_END
