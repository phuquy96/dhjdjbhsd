#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#include <TargetConditionals.h>
#include "imgui.h"
#include "imgui_impl_ios.h"

// Biến trạng thái Menu và Tính năng
bool showMenu = false;
bool espLine = false;
bool espBox = false;
bool healthBar = false;
bool espName = false;
bool enemyCount = false;
bool espDistance = false;
bool espBone = false;
bool speedHackEnabled = false;
float speedMultiplier = 1.0f;

// View chứa ImGui để fix lỗi chặn touch toàn màn hình
@interface ImGuiOverlayView : UIView
@property (nonatomic, strong) UIButton *floatingButton;
@end

@implementation ImGuiOverlayView

-instancetype.objc_designate_init(initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        
        // Tạo nút tròn avatar nổi
        self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingButton.frame = CGRectMake(50, 100, 50, 50);
        self.floatingButton.layer.cornerRadius = 25;
        self.floatingButton.clipsToBounds = YES;
        self.floatingButton.layer.borderWidth = 2.0f;
        self.floatingButton.layer.borderColor = [UIColor whiteColor].CGColor;
        
        // Load avatar từ URL hoặc local asset
        NSURL *url = [NSURL URLWithString:@"https://i.ibb.co/n40bJLx/Screenshot-2026-09-12-193416.png"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            if (data) {
                UIImage *img = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.floatingButton setImage:img forState:UIControlStateNormal];
                });
            }
        });
        
        [self.floatingButton addTarget:self action:@selector(floatingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Cho phép kéo thả nút tròn
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingButton addGestureRecognizer:pan];
        
        [self addSubview:self.floatingButton];
    }
    return self;
}

- (void)floatingButtonTapped:(id)sender {
    showMenu = !showMenu;
}

- (void)handlePan:(UIPanGestureRecognizer * _Nonnull)gesture {
    CGPoint translation = [gesture translationInView:self];
    CGPoint center = gesture.view.center;
    gesture.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self];
}

// QUAN TRỌNG: Fix lỗi đè touch - Chỉ nhận chạm vào nút hoặc khi menu mở, ngoài ra cho xuyên thấu
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        // Nếu chạm vào vùng trống của overlay view, kiểm tra xem có bấm trúng nút tròn hay menu không
        CGRect btnFrame = self.floatingButton.frame;
        if (CGRectContainsPoint(btnFrame, point)) {
            return hitView;
        }
        if (showMenu) {
            // Cho phép ImGui nhận touch khi mở menu (vùng menu hình vuông)
            // Trả về self để ImGui xử lý touch event
            return self;
        }
        return nil; // Xuyên thấu toàn bộ touch xuống game Free Fire (giúp bấm được đăng nhập, sảnh,...)
    }
    return hitView;
}

@end

// Hook Speed Hack Free Fire (Anti-Rubberband: chỉnh timeScale hoặc velocity gốc thay vì gán cứng liên tục gây giựt)
void ApplySpeedHack(float speed) {
    if (!speedHackEnabled) return;
    
    // Offset Unity Time.timeScale hoặc Native Player Speed tương ứng với bản Free Fire hiện tại
    // Ví dụ cơ chế il2cpp Time scale:
    // void (*SetTimeScale)(float) = (void (*)(float))Offset_SetTimeScale;
    // SetTimeScale(speed);
}

// Khởi tạo ImGui Style (Nền đen, bo tròn góc, nút iOS style)
void SetupImGuiStyle() {
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 12.0f; // Bo tròn góc menu hình vuông
    style.FrameRounding = 6.0f;
    style.WindowBorderSize = 1.0f;
    
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_WindowBg] = ImVec4(0.08f, 0.08f, 0.08f, 0.94f); // Nền đen mờ ImGui
    colors[ImGuiCol_FrameBg] = ImVec4(0.20f, 0.20f, 0.20f, 0.54f);
    colors[ImGuiCol_CheckMark] = ImVec4(1.00f, 1.00f, 1.00f, 1.00f); // Nút bật màu trắng
    colors[ImGuiCol_SliderGrab] = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
}
