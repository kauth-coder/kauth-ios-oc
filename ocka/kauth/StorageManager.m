//
//  StorageManager.m
//  ocka
//

#import "StorageManager.h"

static NSString * const kLicenseKey = @"kauth_saved_license";

@implementation StorageManager

+ (void)saveLicense:(NSString *)license {
    if (license && license.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:license forKey:kLicenseKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (nullable NSString *)getSavedLicense {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kLicenseKey];
}

+ (void)clearLicense {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLicenseKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
