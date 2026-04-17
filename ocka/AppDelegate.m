//
//  AppDelegate.m
//  ocka
//
//  Created by kauth-coder on 2026/3/31.
//

#import "AppDelegate.h"
#import "kauth/Config.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 验证配置完整性，配置不完整则终止运行
    if (![Config validateConfiguration]) {
        #ifdef DEBUG
        @throw [NSException exceptionWithName:@"ConfigInvalid" reason:@"请检查 Config.m 中的配置" userInfo:nil];
        #else
        exit(0);
        #endif
    }
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
}


@end
