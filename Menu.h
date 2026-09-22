#pragma once
#import <UIKit/UIKit.h>

@interface ImGuiOverlayView : UIView
@property (nonatomic, strong) UIButton *floatingButton;
@end

void SetupImGuiStyle();
