#import <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#include <vector>
#include <string>

// Định nghĩa cấu trúc vị trí Player trong Game (Memory Offset chuẩn Unity IL2CPP)
struct Vector3 {
    float x, y, z;
};

struct PlayerData {
    uint64_t playerObject;
    Vector3 position;
    bool isAlive;
    int teamID;
};

// Biến trạng thái Menu & ESP
bool g_MenuVisible = false;
bool g_ESPEnabled = false;
UIButton *g_FloatingButton = nil;
UIView *g_MenuView = nil;

// Hàm giả lập quét danh sách player từ bộ nhớ game Free Fire (IL2CPP)
std::vector<PlayerData> GetFreeFirePlayers() {
    std::vector<PlayerData> players;
    // THỰC CHIẾN: Đọc offset từ Il2Cpp Domain / GameObject Manager của Free Fire
    // Code dưới là khung chuẩn xử lý memory hook trên iOS
    uint64_t il2cpp_base = (uint64_t)_objc_getMetaClass("UnityAppController"); // Hook base app
    if (!il2cpp_base) return players;

    // Ví dụ giả lập lấy danh sách player thật trong map
    // Trong môi trường mod IPA thực tế, chỗ này sẽ duyệt qua List<PlayerController>
    return players; 
}

// Giao diện Menu nổi kiểu iOS (Floating Button & Rounded Panel)
@interface MenuController : NSObject
+ (void)toggleMenu:(UIButton *)sender;
+ (void)setupOverlay;
@end

@implementation MenuController

+ (void)setupOverlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        // Tạo nút bấm nổi mở menu ngoài màn hình game Free Fire
        g_FloatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_FloatingButton.frame = CGRectMake(50, 100, 55, 55);
        g_FloatingButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
        g_FloatingButton.layer.cornerRadius = 27.5;
        g_FloatingButton.layer.borderWidth = 1.5;
        g_FloatingButton.layer.borderColor = [[UIColor systemGreenColor] CGColor];
        [g_FloatingButton setTitle:@"FF" forState:UIControlStateNormal];
        [g_FloatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_FloatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [g_FloatingButton addTarget:self action:@selector(toggleMenu:) forControlEvents:UIControlEventTouchUpInside];
        
        [window addSubview:g_FloatingButton];

        // Tạo khung Menu bo tròn góc kiểu iOS 26
        g_MenuView = [[UIView alloc] initWithFrame:CGRectMake(120, 100, 280, 320)];
        g_MenuView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.92];
        g_MenuView.layer.cornerRadius = 24;
        g_MenuView.layer.masksToBounds = YES;
        g_MenuView.layer.borderWidth = 1.0;
        g_MenuView.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.15] CGColor];
        g_MenuView.hidden = YES;

        // Tiêu đề Menu
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 280, 30)];
        titleLabel.text = @"FREE FIRE VIP MENU";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [g_MenuView addSubview:titleLabel];

        // Nút bật ESP trong Menu
        UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 70, 0, 0)];
        [espSwitch setOn:NO];
        [espSwitch addTarget:self action:@selector(espSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        
        UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 160, 30)];
        espLabel.text = @"ESP Line & Count";
        espLabel.textColor = [UIColor whiteColor];
        espLabel.font = [UIFont systemFontOfSize:14];

        [g_MenuView addSubview:espSwitch];
        [g_MenuView addSubview:espLabel];

        [window addSubview:g_MenuView];
    });
}

+ (void)toggleMenu:(UIButton *)sender {
    g_MenuVisible = !g_MenuVisible;
    g_MenuView.hidden = !g_MenuVisible;
}

+ (void)espSwitchChanged:(UISwitch *)sender {
    g_ESPEnabled = sender.isOn;
}

@end

// Khởi chạy khi IPA được load vào tiến trình Free Fire
__attribute__((constructor)) void entry() {
    [MenuController setupOverlay];
}