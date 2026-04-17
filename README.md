# KAuth iOS SDK (Objective-C)

KAuth 卡密验证系统 iOS 客户端 SDK，基于 Objective-C 实现，支持 AES/ECB 请求加密、RSA 签名验证、自动心跳等功能。

## 环境要求

- Xcode 15+
- iOS 15.6+
- 无第三方依赖，仅使用系统框架（Security、CommonCrypto、UIKit）

## 项目结构

```
ocka/
├── kauth/                      # SDK 核心模块
│   ├── Config.h/.m             # 配置（域名、程序ID、密钥、公钥）
│   ├── CryptoUtil.h/.m         # 加密工具（AES/ECB、RSA、MD5）
│   ├── SignTools.h/.m          # 请求/响应签名与验签
│   ├── NetworkManager.h/.m     # 网络层（加密、签名、发送、验签、解密）
│   ├── APIService.h/.m         # 业务 API（25+ 接口 + 心跳管理）
│   └── StorageManager.h/.m     # 本地存储（卡密持久化）
├── ViewController.m            # 登录页（卡密登录 + 解绑设备）
├── HomeViewController.m        # 主页（服务状态 + 实时心跳）
└── Base.lproj/Main.storyboard  # NavigationController 导航
```

## 快速开始

### 1. 配置参数

在 `Config.m` 中填入你的项目信息：

```objc
+ (NSString *)apiDomain {
    return @"https://api.kauth.cn";
}

+ (NSString *)programId {
    return @"你的程序ID";
}

+ (NSString *)programSecret {
    return @"你的程序密钥";   // 16位，用于 AES 加密
}

+ (NSString *)merchantPublicKey {
    return @"你的商户RSA公钥"; // PKCS#8 Base64 格式
}
```

### 2. 获取设备 ID

设备 ID 首次从 `identifierForVendor` 获取后自动存入 **Keychain**，卸载重装也不会改变：

```objc
NSString *deviceId = [APIService getDeviceId];
```

### 3. 卡密登录

```objc
[APIService kaLoginWithLicense:@"卡密"
                      deviceId:[APIService getDeviceId]
                    completion:^(BOOL success, NSDictionary *data, NSString *message) {
    if (success) {
        // data 包含用户信息，token 已自动保存在 NetworkManager 中
        // 后续 API 调用自动携带 token
    } else {
        NSLog(@"登录失败: %@", message);
    }
}];
```

### 4. 账号密码登录

```objc
[APIService pwdLoginWithName:@"用户名"
                    password:@"密码"
                    deviceId:[APIService getDeviceId]
                 captchaCode:nil
                 captchaUuid:nil
                  completion:^(BOOL success, NSDictionary *data, NSString *message) {
    // ...
}];
```

### 5. 试用登录

```objc
[APIService trialLoginWithDeviceId:[APIService getDeviceId]
                        completion:^(BOOL success, NSDictionary *data, NSString *message) {
    // ...
}];
```

### 6. 启动自动心跳

登录成功后启动心跳，SDK 会自动按服务端下发的间隔发送 pong 请求：

```objc
[APIService startAutoPongWithMaxFail:10
    onPong:^(BOOL success, NSString *message) {
        if (success) {
            NSLog(@"心跳正常: %@", message);
        } else {
            NSLog(@"心跳异常: %@", message);
        }
    }
    onFail:^(NSString *reason, NSString *message) {
        // reason 取值:
        //   "MAXFAIL_CONNECTION" — 连续网络失败达到上限
        //   "BUSINESS_ERROR"    — 业务错误（账号冻结/过期/被踢）
        //   "INVALID_LOGIN"     — 未登录或登录信息丢失
        NSLog(@"心跳终止 [%@]: %@", reason, message);
        [APIService stopAutoPong];
    }
];
```

停止心跳：

```objc
[APIService stopAutoPong];
```

### 7. 退出登录

```objc
[APIService stopAutoPong];
[APIService loginOutWithCompletion:^(BOOL success, NSDictionary *data, NSString *message) {
    [NetworkManager clearSession]; // 清除 token
}];
```

## 全部 API 一览

### 用户认证

| 方法 | 说明 |
|------|------|
| `kaLoginWithLicense:deviceId:completion:` | 卡密登录 |
| `pwdLoginWithName:password:deviceId:captchaCode:captchaUuid:completion:` | 账号密码登录 |
| `trialLoginWithDeviceId:completion:` | 试用登录 |
| `loginOutWithCompletion:` | 退出登录 |
| `registerWithLoginName:password:kaPassword:nickName:deviceId:captchaCode:captchaUuid:completion:` | 用户注册 |
| `getCaptchaWithUuid:completion:` | 获取图形验证码 |
| `getUserInfoWithCompletion:` | 获取用户信息 |
| `pongWithCompletion:` | 单次心跳 |

### 设备管理

| 方法 | 说明 |
|------|------|
| `getDeviceId` | 获取持久化设备唯一 ID |
| `unbindDeviceWithKaPwd:deviceId:completion:` | 卡密方式解绑设备 |
| `unbindDeviceWithLoginName:password:deviceId:captchaCode:captchaUuid:completion:` | 账密方式解绑设备 |
| `cardUnBindDeviceWithCompletion:` | 已登录状态下卡密解绑 |

### 账户操作

| 方法 | 说明 |
|------|------|
| `rechargeWithLoginName:kaPassword:deviceId:captchaCode:captchaUuid:completion:` | 账户充值 |
| `rechargeKaWithCardPwd:rechargeCardPwd:completion:` | 以卡充卡 |
| `changePasswordWithLoginName:oldPassword:newPassword:confirmPassword:captchaCode:captchaUuid:completion:` | 修改密码 |

### 程序信息

| 方法 | 说明 |
|------|------|
| `getProgramDetailWithCompletion:` | 获取程序详情 |
| `getServerTimeWithCompletion:` | 获取服务器时间 |

### 自定义配置

| 方法 | 说明 |
|------|------|
| `updateUserConfig:completion:` | 更新用户配置 |
| `getUserConfigWithCompletion:` | 获取用户配置 |
| `updateKaConfig:completion:` | 更新卡密配置 |
| `getKaConfigWithCompletion:` | 获取卡密配置 |

### 远程控制

| 方法 | 说明 |
|------|------|
| `getRemoteVarWithKey:completion:` | 获取远程变量 |
| `getRemoteDataWithKey:completion:` | 获取远程数据 |
| `addRemoteDataWithKey:value:completion:` | 新增远程数据 |
| `updateRemoteDataWithKey:value:completion:` | 更新远程数据 |
| `deleteRemoteDataWithKey:completion:` | 删除远程数据 |
| `callFunctionWithName:params:completion:` | 调用云函数 |
| `getNewestScriptWithName:completion:` | 获取最新脚本版本 |
| `getScriptDownloadWithName:versionNumber:completion:` | 下载脚本 |

### 心跳管理

| 方法 | 说明 |
|------|------|
| `startAutoPongWithMaxFail:onPong:onFail:` | 启动自动心跳 |
| `stopAutoPong` | 停止自动心跳 |

## 通信安全机制

所有请求经过以下安全处理：

```
请求: 参数 → JSON → AES/ECB 加密 → Base64 → 发送
签名: "url:{path}\nbody:{json}\nnonce:{nonce}\ntime:{time}" → MD5 → RSA公钥加密
响应: 时间戳校验(120s) → AES解密 → RSA签名验证 → 返回明文数据
```

- **AES/ECB/NoPadding** — 128-bit 密钥，手动零填充至 16 字节对齐
- **RSA 签名** — PKCS#1 公钥加密，支持 1024/2048/4096 位密钥自动检测
- **防重放** — 请求携带 nonce + timestamp，响应校验 120 秒有效期

## 本地存储

| 存储方式 | 内容 | 说明 |
|----------|------|------|
| **Keychain** | 设备 ID | 卸载重装不丢失 |
| **NSUserDefaults** | 卡密 | 下次打开自动填充 |
| **内存** | Token / UserInfo | 随 NetworkManager 生命周期 |

## 回调格式

所有 API 使用统一的回调类型：

```objc
typedef void(^APICompletion)(BOOL success, NSDictionary *_Nullable data, NSString *_Nullable message);
```

- `success` — 请求是否成功（HTTP 200 且业务 code=200）
- `data` — 服务端返回的 data 字段（已解密）
- `message` — 服务端消息或错误描述

## License

MIT
