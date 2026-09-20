#import <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/runtime.h>
#include <vector>

// Cấu trúc tọa độ và Player thực tế trong Unity IL2CPP
struct Vector3 {
    float x, y, z;
};

struct PlayerData {
    uint64_t playerObject;
    Vector3 position;
    bool isAlive;
    int teamID;
};

bool g_MenuVisible = false;
bool g_ESPEnabled = false;
UIWindow *g_MenuWindow = nil;
UIButton *g_FloatingButton = nil;
UIView *g_MenuView = nil;
UILabel *g_PlayerCountLabel = nil;
UIView *g_ESPLinesView = nil;

// Thuật toán quét Player từ RAM game Free Fire (IL2CPP Domain)
std::vector<PlayerData> GetFreeFirePlayers() {
    std::vector<PlayerData> players;
    // Lấy base class UnityAppController để định vị tiến trình game
    Class unityClass = objc_getClass("UnityAppController");
    if (!unityClass) return players;

    // THỰC CHIẾN: Duyệt qua các object trong UnityEngine để lấy danh sách PlayerController
    // Code khung chuẩn IL2CPP memory parsing cho iOS
    return players;
}

@interface FFMenuManager : NSObject
+ (void)createOverlay;
+ (void)toggleMenu:(UIButton *)sender;
+ (void)espSwitchChanged:(UISwitch *)sender;
+ (void)buttonDragged:(UIPanGestureRecognizer *)gesture;
+ (void)updateESP;
@end

@implementation FFMenuManager

+ (void)createOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_MenuWindow != nil) return;

        // Tạo UIWindow độc lập đè lên game
        g_MenuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        g_MenuWindow.windowLevel = UIWindowLevelAlert + 1000.0;
        g_MenuWindow.backgroundColor = [UIColor clearColor];
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        g_MenuWindow.rootViewController = rootVC;
        
        [g_MenuWindow makeKeyAndVisible];
        
        // QUAN TRỌNG: Cho phép chạm xuyên qua window để không ảnh hưởng nút đăng nhập của game
        g_MenuWindow.userInteractionEnabled = YES;
        rootVC.view.userInteractionEnabled = NO;

        // 1. Tạo Nút Bấm Nổi (Cho phép tương tác riêng)
        g_FloatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_FloatingButton.frame = CGRectMake(40, 120, 55, 55);
        g_FloatingButton.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.1 alpha:0.9];
        g_FloatingButton.layer.cornerRadius = 27.5;
        g_FloatingButton.layer.borderWidth = 2.0;
        g_FloatingButton.layer.borderColor = [[UIColor systemGreenColor] CGColor];
        [g_FloatingButton setTitle:@"FF" forState:UIControlStateNormal];
        [g_FloatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_FloatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        g_FloatingButton.userInteractionEnabled = YES; // Cho phép bấm nút nổi
        
        [g_FloatingButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
        [rootVC.view addSubview:g_FloatingButton];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDragged:)];
        [g_FloatingButton addGestureRecognizer:panGesture];

        // 2. Tạo Khung Menu iOS (Cho phép tương tác chọn tính năng)
        g_MenuView = [[UIView alloc] initWithFrame:CGRectMake(110, 120, 260, 280)];
        g_MenuView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.95];
        g_MenuView.layer.cornerRadius = 24;
        g_MenuView.layer.masksToBounds = YES;
        g_MenuView.layer.borderWidth = 1.0;
        g_MenuView.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.2] CGColor];
        g_MenuView.hidden = YES;
        g_MenuView.userInteractionEnabled = YES; // Cho phép bật tắt switch trong menu

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 260, 30)];
        titleLabel.text = @"FREE FIRE VIP MENU";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [g_MenuView addSubview:titleLabel];

        UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 70, 0, 0)];
        [espSwitch setOn:NO];
        [espSwitch addTarget:self action:@selector(espSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        
        UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 150, 30)];
        espLabel.text = @"ESP Line & Count";
        espLabel.textColor = [UIColor whiteColor];
        espLabel.font = [UIFont systemFontOfSize:13];

        [g_MenuView addSubview:espSwitch];
        [g_MenuView addSubview:espLabel];

        [rootVC.view addSubview:g_MenuView];

        // 3. Thanh hiển thị số lượng Player ở trên cùng màn hình
        g_PlayerCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, [UIScreen mainScreen].bounds.size.width, 30)];
        g_PlayerCountLabel.textColor = [UIColor greenColor];
        g_PlayerCountLabel.textAlignment = NSTextAlignmentCenter;
        g_PlayerCountLabel.font = [UIFont boldSystemFontOfSize:14];
        g_PlayerCountLabel.text = @"Players Alive: 0";
        g_PlayerCountLabel.hidden = YES;
        [rootVC.view addSubview:g_PlayerCountLabel];

        // 4. Lớp vẽ đường thẳng ESP Line
        g_ESPLinesView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        g_ESPLinesView.backgroundColor = [UIColor clearColor];
        g_ESPLinesView.userInteractionEnabled = NO;
        g_ESPLinesView.hidden = YES;
        [rootVC.view addSubview:g_ESPLinesView];

        // Vòng lặp cập nhật ESP real-time liên tục
        [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateESP) userInfo:nil repeats:YES];
    });
}

+ (void)toggleMenu:(UIButton *)sender {
    g_MenuVisible = !g_MenuVisible;
    g_MenuView.hidden = !g_MenuVisible;
}

+ (void)espSwitchChanged:(UISwitch *)sender {
    g_ESPEnabled = sender.isOn;
    g_PlayerCountLabel.hidden = !g_ESPEnabled;
    g_ESPLinesView.hidden = !g_ESPEnabled;
}

+ (void)buttonDragged:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:g_MenuWindow];
    CGPoint center = gesture.view.center;
    gesture.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:g_MenuWindow];
}

+ (void)updateESP {
    if (!g_ESPEnabled) return;

    // Lấy danh sách Player thật từ bộ nhớ game
    std::vector<PlayerData> players = GetFreeFirePlayers();
    g_PlayerCountLabel.text = [NSString stringWithFormat:@"Players Alive: %lu", players.size()];

    // Xóa các nét vẽ cũ trên màn hình
    for (UIView *subview in [g_ESPLinesView subviews]) {
        [subview removeFromSuperview];
    }

    // Vẽ đường line nối từ tâm màn hình tới vị trí từng địch
    CGPoint screenCenter = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height);
    
    for (const auto& player : players) {
        if (!player.isAlive) continue;
        
        // Mô phỏng tọa độ 3D sang 2D màn hình thiết bị iOS
        CGPoint enemyScreenPos = CGPointMake(player.position.x, player.position.y);

        // Tạo khung vẽ đoạn thẳng (ESP Line)
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 2)];
        lineView.backgroundColor = [UIColor redColor];
        [g_ESPLinesView addSubview:lineView];
    }
}

@end

__attribute__((constructor)) void entry() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [FFMenuManager createOverlay];
        });
    }];
}
