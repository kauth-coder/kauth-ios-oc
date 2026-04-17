//
//  HomeViewController.m
//  ocka
//

#import "HomeViewController.h"
#import "kauth/APIService.h"
#import "kauth/NetworkManager.h"
#import "kauth/StorageManager.h"

@interface HomeViewController ()

@property (nonatomic, strong) UILabel *welcomeLabel;
@property (nonatomic, strong) UILabel *expireLabel;
@property (nonatomic, strong) UILabel *heartbeatStatusLabel;
@property (nonatomic, strong) UIButton *logoutButton;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"主页";
    self.navigationItem.hidesBackButton = YES;
    [self setupUI];
    [self startHeartbeat];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // 欢迎标签
    self.welcomeLabel = [[UILabel alloc] init];
    NSString *nickName = self.loginData[@"nickName"] ?: @"用户";
    self.welcomeLabel.text = [NSString stringWithFormat:@"欢迎，%@", nickName];
    self.welcomeLabel.font = [UIFont systemFontOfSize:26 weight:UIFontWeightBold];
    self.welcomeLabel.textAlignment = NSTextAlignmentCenter;
    self.welcomeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.welcomeLabel];

    // 到期时间卡片
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor secondarySystemBackgroundColor];
    card.layer.cornerRadius = 16;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];

    UIImageView *clockIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"clock.badge.checkmark"]];
    clockIcon.tintColor = [UIColor systemGreenColor];
    clockIcon.contentMode = UIViewContentModeScaleAspectFit;
    clockIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:clockIcon];

    UILabel *cardTitle = [[UILabel alloc] init];
    cardTitle.text = @"服务状态";
    cardTitle.font = [UIFont systemFontOfSize:14];
    cardTitle.textColor = [UIColor secondaryLabelColor];
    cardTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardTitle];

    self.expireLabel = [[UILabel alloc] init];
    self.expireLabel.text = self.loginMsg ?: @"已登录";
    self.expireLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    self.expireLabel.textColor = [UIColor labelColor];
    self.expireLabel.numberOfLines = 0;
    self.expireLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.expireLabel];

    // 心跳状态卡片
    UIView *heartbeatCard = [[UIView alloc] init];
    heartbeatCard.backgroundColor = [UIColor secondarySystemBackgroundColor];
    heartbeatCard.layer.cornerRadius = 16;
    heartbeatCard.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:heartbeatCard];

    UIImageView *heartIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart.fill"]];
    heartIcon.tintColor = [UIColor systemRedColor];
    heartIcon.contentMode = UIViewContentModeScaleAspectFit;
    heartIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [heartbeatCard addSubview:heartIcon];

    UILabel *hbTitle = [[UILabel alloc] init];
    hbTitle.text = @"心跳状态";
    hbTitle.font = [UIFont systemFontOfSize:14];
    hbTitle.textColor = [UIColor secondaryLabelColor];
    hbTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [heartbeatCard addSubview:hbTitle];

    self.heartbeatStatusLabel = [[UILabel alloc] init];
    self.heartbeatStatusLabel.text = @"⏳ 等待首次心跳...";
    self.heartbeatStatusLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.heartbeatStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [heartbeatCard addSubview:self.heartbeatStatusLabel];

    // 退出登录按钮
    self.logoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.logoutButton setTitle:@"退出登录" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.logoutButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.logoutButton.backgroundColor = [UIColor systemRedColor];
    self.logoutButton.layer.cornerRadius = 12;
    self.logoutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.logoutButton addTarget:self action:@selector(logoutTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.logoutButton];

    // 布局
    [NSLayoutConstraint activateConstraints:@[
        [self.welcomeLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:40],
        [self.welcomeLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.welcomeLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],

        [card.topAnchor constraintEqualToAnchor:self.welcomeLabel.bottomAnchor constant:32],
        [card.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [card.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],

        [clockIcon.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [clockIcon.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [clockIcon.widthAnchor constraintEqualToConstant:28],
        [clockIcon.heightAnchor constraintEqualToConstant:28],

        [cardTitle.centerYAnchor constraintEqualToAnchor:clockIcon.centerYAnchor],
        [cardTitle.leadingAnchor constraintEqualToAnchor:clockIcon.trailingAnchor constant:10],

        [self.expireLabel.topAnchor constraintEqualToAnchor:clockIcon.bottomAnchor constant:12],
        [self.expireLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [self.expireLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [self.expireLabel.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],

        [heartbeatCard.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:16],
        [heartbeatCard.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [heartbeatCard.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],

        [heartIcon.topAnchor constraintEqualToAnchor:heartbeatCard.topAnchor constant:20],
        [heartIcon.leadingAnchor constraintEqualToAnchor:heartbeatCard.leadingAnchor constant:20],
        [heartIcon.widthAnchor constraintEqualToConstant:28],
        [heartIcon.heightAnchor constraintEqualToConstant:28],

        [hbTitle.centerYAnchor constraintEqualToAnchor:heartIcon.centerYAnchor],
        [hbTitle.leadingAnchor constraintEqualToAnchor:heartIcon.trailingAnchor constant:10],

        [self.heartbeatStatusLabel.topAnchor constraintEqualToAnchor:heartIcon.bottomAnchor constant:12],
        [self.heartbeatStatusLabel.leadingAnchor constraintEqualToAnchor:heartbeatCard.leadingAnchor constant:20],
        [self.heartbeatStatusLabel.trailingAnchor constraintEqualToAnchor:heartbeatCard.trailingAnchor constant:-20],
        [self.heartbeatStatusLabel.bottomAnchor constraintEqualToAnchor:heartbeatCard.bottomAnchor constant:-20],

        [self.logoutButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-30],
        [self.logoutButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.logoutButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.logoutButton.heightAnchor constraintEqualToConstant:50],
    ]];
}

#pragma mark - 心跳

- (void)startHeartbeat {
    __weak typeof(self) weakSelf = self;
    [APIService startAutoPongWithMaxFail:10 onPong:^(BOOL success, NSString *message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        if (success) {
            self.heartbeatStatusLabel.text = @"🟢 心跳正常";
            self.heartbeatStatusLabel.textColor = [UIColor systemGreenColor];
        } else {
            self.heartbeatStatusLabel.text = [NSString stringWithFormat:@"🔴 %@", message];
            self.heartbeatStatusLabel.textColor = [UIColor systemRedColor];
        }
    } onFail:^(NSString *reason, NSString *message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        self.heartbeatStatusLabel.text = [NSString stringWithFormat:@"🔴 %@", message];
        self.heartbeatStatusLabel.textColor = [UIColor systemRedColor];

        if ([reason isEqualToString:@"INVALID_LOGIN"] || [reason isEqualToString:@"BUSINESS_ERROR"]) {
            [self showAlertWithTitle:@"登录失效" message:message handler:^{
                [self navigateBackToLogin];
            }];
        } else {
            [self showAlertWithTitle:@"心跳异常" message:message handler:^{
                [self navigateBackToLogin];
            }];
        }
    }];
}

#pragma mark - 退出登录

- (void)logoutTapped {
    self.logoutButton.enabled = NO;
    [APIService stopAutoPong];
    [APIService loginOutWithCompletion:^(BOOL success, NSDictionary * _Nullable data, NSString * _Nullable message) {
        self.logoutButton.enabled = YES;
        [StorageManager clearLicense];
        [self navigateBackToLogin];
    }];
}

- (void)navigateBackToLogin {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Alert

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message handler:(void(^ _Nullable)(void))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (handler) handler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)dealloc {
    [APIService stopAutoPong];
}

@end
