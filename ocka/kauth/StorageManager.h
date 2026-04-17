//
//  StorageManager.h
//  ocka
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StorageManager : NSObject

+ (void)saveLicense:(NSString *)license;
+ (nullable NSString *)getSavedLicense;
+ (void)clearLicense;

@end

NS_ASSUME_NONNULL_END
