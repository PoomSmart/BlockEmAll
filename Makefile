PACKAGE_VERSION = 0.0.2.1

TARGET = iphone:clang:latest:9.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BlockEmAll
BlockEmAll_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk


