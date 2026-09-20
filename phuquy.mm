#import <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/runtime.h>
#include <vector>

// Định nghĩa cấu trúc
struct Vector3 { float x, y, z; };
struct PlayerData { uint64_t playerObject; Vector3 position; bool isAlive; int teamID; };

bool g_MenuVisible = false;
bool g_ESPEnabled = false;
UIWindow *g_MenuWindow = nil;
UIButton *g_FloatingButton = nil;
UIView *g_MenuView = nil;

@interface FFMenuManager : NSObject
+ (void)createOverlay;
+ (void)toggleMenu:(UIButton *)sender;
+ (void)espSwitchChanged:(UISwitch *)sender;
+ (void)buttonDragged:(UIPanGestureRecognizer *)gesture;
@end

@implementation FFMenuManager

+ (void)createOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_MenuWindow != nil) return;

        // Tạo UIWindow độc lập
        g_MenuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        g_MenuWindow.windowLevel = UIWindowLevelAlert + 1000.0;
        g_MenuWindow.backgroundColor = [UIColor clearColor];
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        g_MenuWindow.rootViewController = rootVC;
        
        [g_MenuWindow makeKeyAndVisible];
        g_MenuWindow.userInteractionEnabled = YES;

        // Nút bấm nổi
        g_FloatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_FloatingButton.frame = CGRectMake(40, 120, 55, 55);
        g_FloatingButton.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.1 alpha:0.9];
        g_FloatingButton.layer.cornerRadius = 27.5;
        g_FloatingButton.layer.borderWidth = 2.0;
        g_FloatingButton.layer.borderColor = [[UIColor systemGreenColor] CGColor];
        [g_FloatingButton setTitle:@"FF" forState:UIControlStateNormal];
        [g_FloatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_FloatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        
        [g_FloatingButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
        [rootVC.view addSubview:g_FloatingButton];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDragged:)];
        [g_FloatingButton addGestureRecognizer:panGesture];

        // Khung Menu iOS
        g_MenuView = [[UIView alloc] initWithFrame:CGRectMake(110, 120, 260, 280)];
        g_MenuView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.95];
        g_MenuView.layer.cornerRadius = 24;
        g_MenuView.layer.masksToBounds = YES;
        g_MenuView.layer.borderWidth = 1.0;
        g_MenuView.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.2] CGColor];
        g_MenuView.hidden = YES;

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
    });
}

+ (void)toggleMenu:(UIButton *)sender {
    g_MenuVisible = !g_MenuVisible;
    g_MenuView.hidden = !g_MenuVisible;
}

+ (void)espSwitchChanged:(UISwitch *)sender {
    g_ESPEnabled = sender.isOn;
}

+ (void)buttonDragged:(UIPanGestureRecognizer *)gesture {
    UIWindow *window = g_MenuWindow;
    CGPoint translation = [gesture translationInView:window];
    CGPoint center = gesture.view.center;
    gesture.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:window];
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
