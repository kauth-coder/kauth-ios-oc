//
//  CryptoUtil.m
//  ocka
//

#import "CryptoUtil.h"
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>

@implementation CryptoUtil

#pragma mark - MD5

+ (NSString *)md5:(NSString *)plainText {
    if (!plainText) return @"";
    const char *cStr = [plainText UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02x", digest[i]];
    }
    return [result copy];
}

#pragma mark - AES/ECB/NoPadding

+ (nullable NSString *)aesEncrypt:(NSString *)content secret:(NSString *)secret {
    if (!content || !secret) return nil;
    NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [self aesKeyFromSecret:secret];

    // Zero-pad to multiple of 16
    NSMutableData *paddedData = [contentData mutableCopy];
    NSUInteger remainder = paddedData.length % kCCBlockSizeAES128;
    if (remainder != 0) {
        NSUInteger padLen = kCCBlockSizeAES128 - remainder;
        uint8_t zeros[16] = {0};
        [paddedData appendBytes:zeros length:padLen];
    }

    size_t bufferSize = paddedData.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;

    CCCryptorStatus status = CCCrypt(kCCEncrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionECBMode, // ECB + no padding
                                     keyData.bytes, keyData.length,
                                     NULL,
                                     paddedData.bytes, paddedData.length,
                                     buffer, bufferSize,
                                     &numBytesEncrypted);

    if (status != kCCSuccess) {
        free(buffer);
        NSLog(@"[KAuth] AES encrypt failed: %d", status);
        return nil;
    }

    NSData *encryptedData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted freeWhenDone:YES];
    return [encryptedData base64EncodedStringWithOptions:0];
}

+ (nullable NSString *)aesDecrypt:(NSString *)content secret:(NSString *)secret {
    if (!content || !secret) return nil;
    NSData *encryptedData = [[NSData alloc] initWithBase64EncodedString:content options:0];
    if (!encryptedData) return nil;
    NSData *keyData = [self aesKeyFromSecret:secret];

    size_t bufferSize = encryptedData.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;

    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionECBMode,
                                     keyData.bytes, keyData.length,
                                     NULL,
                                     encryptedData.bytes, encryptedData.length,
                                     buffer, bufferSize,
                                     &numBytesDecrypted);

    if (status != kCCSuccess) {
        free(buffer);
        NSLog(@"[KAuth] AES decrypt failed: %d", status);
        return nil;
    }

    NSData *decryptedData = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted freeWhenDone:YES];
    // Strip trailing zero bytes
    const uint8_t *bytes = decryptedData.bytes;
    NSUInteger len = decryptedData.length;
    while (len > 0 && bytes[len - 1] == 0) {
        len--;
    }
    return [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding];
}

/// 将 secret 补齐/截断到 16 字节作为 AES key
+ (NSData *)aesKeyFromSecret:(NSString *)secret {
    NSData *raw = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *keyData = [NSMutableData dataWithLength:kCCKeySizeAES128];
    [keyData resetBytesInRange:NSMakeRange(0, kCCKeySizeAES128)];
    [keyData replaceBytesInRange:NSMakeRange(0, MIN(raw.length, (NSUInteger)kCCKeySizeAES128))
                       withBytes:raw.bytes];
    return keyData;
}

#pragma mark - RSA

+ (nullable NSString *)rsaEncryptByPublicKey:(NSString *)plainText publicKey:(NSString *)publicKeyB64 {
    if (!plainText || !publicKeyB64) return nil;
    SecKeyRef publicKey = [self publicKeyRefFromBase64:publicKeyB64];
    if (!publicKey) {
        NSLog(@"[KAuth] RSA encrypt: failed to create public key");
        return nil;
    }

    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    CFErrorRef error = NULL;
    CFDataRef encryptedData = SecKeyCreateEncryptedData(publicKey,
                                                        kSecKeyAlgorithmRSAEncryptionPKCS1,
                                                        (__bridge CFDataRef)plainData,
                                                        &error);
    CFRelease(publicKey);

    if (error) {
        NSLog(@"[KAuth] RSA encrypt error: %@", (__bridge NSError *)error);
        CFRelease(error);
        return nil;
    }

    NSString *result = [(__bridge NSData *)encryptedData base64EncodedStringWithOptions:0];
    CFRelease(encryptedData);
    return result;
}

+ (nullable NSString *)rsaDecryptByPublicKey:(NSString *)cipherText publicKey:(NSString *)publicKeyB64 {
    if (!cipherText || !publicKeyB64) return nil;
    SecKeyRef publicKey = [self publicKeyRefFromBase64:publicKeyB64];
    if (!publicKey) {
        NSLog(@"[KAuth] RSA decrypt: failed to create public key");
        return nil;
    }

    NSData *cipherData = [[NSData alloc] initWithBase64EncodedString:cipherText options:0];
    if (!cipherData) {
        CFRelease(publicKey);
        return nil;
    }

    // 公钥"解密"实际上是 raw RSA operation: cipher^e mod n
    // iOS 不支持用公钥调用 SecKeyCreateDecryptedData，所以用 Raw encrypt 做 sig^e mod n
    CFErrorRef error = NULL;
    CFDataRef rawData = SecKeyCreateEncryptedData(publicKey,
                                                  kSecKeyAlgorithmRSAEncryptionRaw,
                                                  (__bridge CFDataRef)cipherData,
                                                  &error);
    CFRelease(publicKey);

    if (error) {
        NSLog(@"[KAuth] RSA public key decrypt error: %@", (__bridge NSError *)error);
        CFRelease(error);
        return nil;
    }

    // 手动去除 PKCS1 Type 1 填充: 0x00 0x01 [0xFF...] 0x00 [plaintext]
    NSData *resultData = [self stripPKCS1Type1Padding:(__bridge NSData *)rawData];
    CFRelease(rawData);

    if (!resultData) return nil;
    return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
}

/// 去除 PKCS1 Type 1 填充
+ (nullable NSData *)stripPKCS1Type1Padding:(NSData *)data {
    if (data.length < 11) return nil; // PKCS1 v1.5 最小长度
    const uint8_t *bytes = data.bytes;
    NSUInteger len = data.length;

    // 格式: 0x00 0x01 [0xFF padding] 0x00 [plaintext]
    if (bytes[0] != 0x00 || bytes[1] != 0x01) return nil;

    NSUInteger i = 2;
    while (i < len && bytes[i] == 0xFF) {
        i++;
    }
    if (i >= len || bytes[i] != 0x00) return nil;
    i++; // skip 0x00

    return [data subdataWithRange:NSMakeRange(i, len - i)];
}

/// 从 Base64 编码的 X.509 DER 公钥创建 SecKeyRef
+ (nullable SecKeyRef)publicKeyRefFromBase64:(NSString *)base64Key {
    // 去掉 PEM 头尾和换行
    NSString *stripped = [base64Key stringByReplacingOccurrencesOfString:@"-----BEGIN PUBLIC KEY-----" withString:@""];
    stripped = [stripped stringByReplacingOccurrencesOfString:@"-----END PUBLIC KEY-----" withString:@""];
    stripped = [stripped stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    stripped = [stripped stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    stripped = [stripped stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSData *derData = [[NSData alloc] initWithBase64EncodedString:stripped options:0];
    if (!derData) return nil;

    // 从 DER 数据中提取裸 RSA 公钥（跳过 X.509 头）
    NSData *strippedData = [self stripX509Header:derData];
    if (!strippedData) strippedData = derData;

    // 自动检测密钥大小
    NSUInteger keySizeInBits = strippedData.length * 8;
    if (keySizeInBits > 4000) keySizeInBits = 4096;
    else if (keySizeInBits > 1800) keySizeInBits = 2048;
    else keySizeInBits = 1024;

    NSDictionary *attributes = @{
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
        (__bridge id)kSecAttrKeyClass: (__bridge id)kSecAttrKeyClassPublic,
        (__bridge id)kSecAttrKeySizeInBits: @(keySizeInBits),
    };

    CFErrorRef error = NULL;
    SecKeyRef key = SecKeyCreateWithData((__bridge CFDataRef)strippedData,
                                         (__bridge CFDictionaryRef)attributes,
                                         &error);
    if (error) {
        NSLog(@"[KAuth] Create public key error: %@", (__bridge NSError *)error);
        CFRelease(error);
        return nil;
    }
    return key;
}

/// 去除 X.509 DER 头，提取裸 RSA 公钥数据
+ (nullable NSData *)stripX509Header:(NSData *)derData {
    if (derData.length < 2) return nil;
    const uint8_t *bytes = derData.bytes;
    NSUInteger idx = 0;

    // 外层 SEQUENCE
    if (bytes[idx++] != 0x30) return nil;
    idx += [self derLengthAt:bytes + idx remaining:derData.length - idx consumed:NULL];

    // AlgorithmIdentifier SEQUENCE
    if (idx >= derData.length || bytes[idx] != 0x30) return nil;
    idx++; // skip tag
    NSUInteger algLen = 0;
    NSUInteger lenBytes = [self derLengthAt:bytes + idx remaining:derData.length - idx consumed:&algLen];
    idx += lenBytes + algLen; // skip algorithm identifier

    // BIT STRING
    if (idx >= derData.length || bytes[idx] != 0x03) return nil;
    idx++; // skip tag
    NSUInteger bitStringLen = 0;
    lenBytes = [self derLengthAt:bytes + idx remaining:derData.length - idx consumed:&bitStringLen];
    idx += lenBytes;

    // skip unused bits byte
    if (idx >= derData.length) return nil;
    idx++;

    return [derData subdataWithRange:NSMakeRange(idx, derData.length - idx)];
}

/// 解析 DER 长度字段，返回长度字段本身占用的字节数，通过 consumed 返回内容长度
+ (NSUInteger)derLengthAt:(const uint8_t *)p remaining:(NSUInteger)remaining consumed:(NSUInteger *)consumed {
    if (remaining < 1) {
        if (consumed) *consumed = 0;
        return 0;
    }
    if (p[0] < 0x80) {
        if (consumed) *consumed = p[0];
        return 1;
    }
    NSUInteger numBytes = p[0] & 0x7F;
    if (numBytes + 1 > remaining) {
        if (consumed) *consumed = 0;
        return 1;
    }
    NSUInteger length = 0;
    for (NSUInteger i = 0; i < numBytes; i++) {
        length = (length << 8) | p[1 + i];
    }
    if (consumed) *consumed = length;
    return 1 + numBytes;
}

@end
