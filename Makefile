THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = phuquy

phuquy_FILES = Menu.mm imgui.cpp imgui_draw.cpp imgui_tables.cpp imgui_widgets.cpp
phuquy_CFLAGS = -fobjc-arc -I.
phuquy_LDFLAGS = -lz

include $(THEOS_MAKE_PATH)/tweak.mk
