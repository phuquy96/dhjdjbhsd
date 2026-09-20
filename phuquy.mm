#import <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#include <objc/runtime.h>
#include <vector>

struct Vector3 { float x, y, z; };
struct PlayerData { 
    uint64_t playerObject; 
    Vector3 position; 
    bool isAlive; 
    int teamID; 
};

bool g_ESPEnabled = false;
UIWindow *g_MenuWindow = nil;
UIButton *g_FloatingButton = nil;
UIView *g_MenuView = nil;
UILabel *g_PlayerCountLabel = nil;
UIView *g_ESPLinesView = nil;

// Giả lập quét tọa độ player thật từ IL2CPP của Unity
std::vector<PlayerData> GetFreeFirePlayers() {
    std::vector<PlayerData> players;
    // THỰC CHIẾN: Hook vào danh sách PlayerController trong game
    return players;
}

// Lớp PassThroughView giúp chạm xuyên qua vùng trống để đăng nhập game bình thường
@interface PassThroughView : UIView
@end

@implementation PassThroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) return nil;
    return hitView;
}
@end

@interface FFMenuManager : NSObject
+ (void)createOverlay;
+ (void)toggleMenu:(UIButton *)sender;
+ (void)toggleESP:(UISwitch *)sender;
+ (void)buttonDragged:(UIPanGestureRecognizer *)gesture;
+ (void)updateESP;
@end

@implementation FFMenuManager

+ (void)createOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_MenuWindow != nil) return;

        g_MenuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        g_MenuWindow.windowLevel = UIWindowLevelAlert + 1000.0;
        g_MenuWindow.backgroundColor = [UIColor clearColor];
        
        UIViewController *rootVC = [[UIViewController alloc] init];
        PassThroughView *passThroughView = [[PassThroughView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        passThroughView.backgroundColor = [UIColor clearColor];
        rootVC.view = passThroughView;
        
        g_MenuWindow.rootViewController = rootVC;
        [g_MenuWindow makeKeyAndVisible];
        g_MenuWindow.userInteractionEnabled = YES;

        // 1. Nút nổi phong cách iOS (Gọn gàng, bấm mở menu)
        g_FloatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_FloatingButton.frame = CGRectMake(40, 120, 55, 55);
        g_FloatingButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.12 alpha:0.85];
        g_FloatingButton.layer.cornerRadius = 27.5;
        g_FloatingButton.layer.borderWidth = 2.0;
        g_FloatingButton.layer.borderColor = [[UIColor systemBlueColor] CGColor];
        [g_FloatingButton setTitle:@"iOS" forState:UIControlStateNormal];
        [g_FloatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_FloatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        
        [g_FloatingButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
        [rootVC.view addSubview:g_FloatingButton];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonDragged:)];
        [g_FloatingButton addGestureRecognizer:panGesture];

        // 2. Menu chính kiểu iOS 26 (Bo tròn, hiện đại)
        g_MenuView = [[UIView alloc] initWithFrame:CGRectMake(110, 120, 240, 200)];
        g_MenuView.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.18 alpha:0.92];
        g_MenuView.layer.cornerRadius = 22;
        g_MenuView.layer.masksToBounds = YES;
        g_MenuView.layer.borderWidth = 1.0;
        g_MenuView.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.15] CGColor];
        g_MenuView.hidden = YES;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, 240, 25)];
        titleLabel.text = @"FREE FIRE HACK";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [g_MenuView addSubview:titleLabel];

        // Công tắc bật tắt ESP Line trực tiếp trong menu
        UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(160, 60, 0, 0)];
        [espSwitch setOn:NO];
        [espSwitch addTarget:self action:@selector(toggleESP:) forControlEvents:UIControlEventValueChanged];
        
        UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 130, 30)];
        espLabel.text = @"ESP Line Real";
        espLabel.textColor = [UIColor whiteColor];
        espLabel.font = [UIFont systemFontOfSize:13];

        [g_MenuView addSubview:espSwitch];
        [g_MenuView addSubview:espLabel];
        [rootVC.view addSubview:g_MenuView];

        // 3. Label đếm số lượng player hiển thị phía trên màn hình
        g_PlayerCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, [UIScreen mainScreen].bounds.size.width, 30)];
        g_PlayerCountLabel.textColor = [UIColor systemGreenColor];
        g_PlayerCountLabel.textAlignment = NSTextAlignmentCenter;
        g_PlayerCountLabel.font = [UIFont boldSystemFontOfSize:13];
        g_PlayerCountLabel.text = @"Players Alive: 0";
        g_PlayerCountLabel.hidden = YES;
        [rootVC.view addSubview:g_PlayerCountLabel];

        // 4. Layer chứa các đường line ESP vẽ thực tế lên màn hình
        g_ESPLinesView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        g_ESPLinesView.backgroundColor = [UIColor clearColor];
        g_ESPLinesView.userInteractionEnabled = NO;
        g_ESPLinesView.hidden = YES;
        [rootVC.view addSubview:g_ESPLinesView];

        // Vòng lặp chạy thuật toán ESP real-time
        [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateESP) userInfo:nil repeats:YES];
    });
}

+ (void)toggleMenu:(UIButton *)sender {
    BOOL isHidden = !g_MenuView.hidden;
    g_MenuView.hidden = isHidden;
}

+ (void)toggleESP:(UISwitch *)sender {
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

    std::vector<PlayerData> players = GetFreeFirePlayers();
    g_PlayerCountLabel.text = [NSString stringWithFormat:@"Players Alive: %lu", players.size()];

    // Xóa bỏ các nét vẽ cũ
    for (UIView *subview in [g_ESPLinesView subviews]) {
        [subview removeFromSuperview];
    }

    // Tọa độ gốc xuất phát đường Line ESP (ví dụ từ chính giữa cạnh dưới màn hình)
    CGPoint screenBottomCenter = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height);

    // Vẽ đường line thực tế nối tới từng player tìm thấy trong map
    for (const auto& player : players) {
        if (!player.isAlive) continue;

        // Khởi tạo view làm đoạn thẳng ESP nối tới địch
        UIView *lineSegment = [[UIView alloc] initWithFrame:CGRectMake(screenBottomCenter.x, screenBottomCenter.y, 1.5, 100)];
        lineSegment.backgroundColor = [UIColor redColor];
        [g_ESPLinesView addSubview:lineSegment];
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
