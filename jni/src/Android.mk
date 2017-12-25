LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := ecl
LOCAL_SRC_FILES := libecl.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := main

SDL_PATH := ../SDL

LOCAL_C_INCLUDES := $(LOCAL_PATH)/$(SDL_PATH)/include \
	$(LOCAL_PATH)/include

LOCAL_SRC_FILES := $(SDL_PATH)/src/main/android/SDL_android_main.c \
	ecl_boot.c \
	main.c

LOCAL_SHARED_LIBRARIES := SDL2

LOCAL_LDFLAGS := -L/home/alf/src/algk/libs/arm64-v8a
LOCAL_LDLIBS := -lGLESv3 -llog -lecl

include $(BUILD_SHARED_LIBRARY)
