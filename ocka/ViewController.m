//
//  ViewController.m
//  ocka
//
//  Created by kauth-coder on 2026/3/31.
//

#import "ViewController.h"
#import "HomeViewController.h"
#import "kauth/APIService.h"
#import "kauth/NetworkManager.h"
#import "kauth/StorageManager.h"

@interface ViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *licenseTextField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *unbindButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadSavedLicense];
}

/// 从本地加载已保存的卡密
- (void)loadSavedLicense {
    NSString *savedLicense = [StorageManager getSavedLicense];
    if (savedLicense && savedLicense.length > 0) {
        self.licenseTextField.text = savedLicense;
    }
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // Logo/标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"卡密登录";
    titleLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:titleLabel];

    // 副标题
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"请输入卡密登录或解绑设备";
    subtitleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.textColor = [UIColor secondaryLabelColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:subtitleLabel];

    // 卡密输入框容器
    UIView *inputContainer = [[UIView alloc] init];
    inputContainer.backgroundColor = [UIColor secondarySystemBackgroundColor];
    inputContainer.layer.cornerRadius = 12;
    inputContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:inputContainer];

    // 卡密图标
    UIImageView *lockIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"key.fill"]];
    lockIcon.tintColor = [UIColor tertiaryLabelColor];
    lockIcon.contentMode = UIViewContentModeScaleAspectFit;
    lockIcon.translatesAutoresizingMaskIntoConstraints = NO;
    [inputContainer addSubview:lockIcon];

    // 卡密输入框
    self.licenseTextField = [[UITextField alloc] init];
    self.licenseTextField.placeholder = @"请输入卡密";
    self.licenseTextField.font = [UIFont systemFontOfSize:16];
    self.licenseTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.licenseTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.licenseTextField.returnKeyType = UIReturnKeyDone;
    self.licenseTextField.delegate = self;
    self.licenseTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [inputContainer addSubview:self.licenseTextField];

    // 登录按钮
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    self.loginButton.layer.cornerRadius = 12;
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];

    // 解绑按钮
    self.unbindButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.unbindButton setTitle:@"解绑设备" forState:UIControlStateNormal];
    [self.unbindButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    self.unbindButton.titleLabel.font = [UIFont systemFontOfSize:15];
    self.unbindButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.unbindButton addTarget:self action:@selector(unbindButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.unbindButton];

    // Loading 指示器
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingIndicator.hidesWhenStopped = YES;
    self.loadingIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loadingIndicator];

    // 布局约束
    [NSLayoutConstraint activateConstraints:@[
        // 标题
        [titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:80],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],

        // 副标题
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:8],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],

        // 输入框容器
        [inputContainer.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:40],
        [inputContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [inputContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [inputContainer.heightAnchor constraintEqualToConstant:56],

        // 锁图标
        [lockIcon.leadingAnchor constraintEqualToAnchor:inputContainer.leadingAnchor constant:16],
        [lockIcon.centerYAnchor constraintEqualToAnchor:inputContainer.centerYAnchor],
        [lockIcon.widthAnchor constraintEqualToConstant:24],
        [lockIcon.heightAnchor constraintEqualToConstant:24],

        // 输入框
        [self.licenseTextField.leadingAnchor constraintEqualToAnchor:lockIcon.trailingAnchor constant:12],
        [self.licenseTextField.trailingAnchor constraintEqualToAnchor:inputContainer.trailingAnchor constant:-16],
        [self.licenseTextField.centerYAnchor constraintEqualToAnchor:inputContainer.centerYAnchor],

        // 登录按钮
        [self.loginButton.topAnchor constraintEqualToAnchor:inputContainer.bottomAnchor constant:24],
        [self.loginButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24],
        [self.loginButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24],
        [self.loginButton.heightAnchor constraintEqualToConstant:50],

        // 解绑按钮
        [self.unbindButton.topAnchor constraintEqualToAnchor:self.loginButton.bottomAnchor constant:16],
        [self.unbindButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],

        // Loading
        [self.loadingIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.loadingIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}

#pragma mark - Actions

- (void)setLoading:(BOOL)loading {
    _isLoading = loading;
    if (loading) {
        [self.loadingIndicator startAnimating];
        self.loginButton.enabled = NO;
        self.unbindButton.enabled = NO;
    } else {
        [self.loadingIndicator stopAnimating];
        self.loginButton.enabled = YES;
        self.unbindButton.enabled = YES;
    }
}

- (void)loginButtonTapped {
    NSString *license = self.licenseTextField.text;
    if (license.length == 0) {
        [self showAlertWithTitle:@"提示" message:@"请输入卡密"];
        return;
    }

    [self.view endEditing:YES];
    [self setLoading:YES];

    NSString *deviceId = [APIService getDeviceId];

    [APIService kaLoginWithLicense:license deviceId:deviceId completion:^(BOOL success, NSDictionary * _Nullable data, NSString * _Nullable message) {
        [self setLoading:NO];

        if (success) {
            // 登录成功，保存卡密
            [StorageManager saveLicense:license];
            // 跳转到主页
            HomeViewController *homeVC = [[HomeViewController alloc] init];
            homeVC.loginMsg = message;
            homeVC.loginData = data;
            [self.navigationController pushViewController:homeVC animated:YES];
        } else {
            [self showAlertWithTitle:@"登录失败" message:message];
        }
    }];
}

- (void)unbindButtonTapped {
    NSString *license = self.licenseTextField.text;
    if (license.length == 0) {
        [self showAlertWithTitle:@"提示" message:@"请输入卡密"];
        return;
    }

    [self.view endEditing:YES];
    [self setLoading:YES];

    NSString *deviceId = [APIService getDeviceId];

    [APIService unbindDeviceWithKaPwd:license deviceId:deviceId completion:^(BOOL success, NSDictionary * _Nullable data, NSString * _Nullable message) {
        [self setLoading:NO];
        if (success) {
            [StorageManager clearLicense];
            [self showAlertWithTitle:@"解绑成功" message:message ?: @"设备已解绑"];
            self.licenseTextField.text = @"";
        } else {
            [self showAlertWithTitle:@"解绑失败" message:message];
        }
    }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
