include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SCloudInfo
SCloudInfo_OBJCC_FILES = /mnt/d/codes/scloudinfo/Tweak.xm
SCloudInfo_FRAMEWORKS = UIKit CydiaSubstrate
LDFLAGS = -Wl,-segalign,0x4000

export ARCHS = armv7 arm64
SCloudInfo_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
