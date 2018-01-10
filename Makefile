-include config.mk

ifndef ANDROID_SDK_PATH
$(error "ANDROID_SDK_PATH is not defined")
endif

ifndef ANDROID_NDK_PATH
$(error "ANDROID_NDK_PATH is not defined")
endif

ifndef ECL_SRC_PATH
$(error "ECL_SRC_PATH is not defined")
endif

ifndef SLIME_PATH
$(error "SLIME_PATH is not defined")
endif

ifndef SDL2_SRC_PATH
$(error "SDL2_SRC_PATH is not defined")
endif

export PATH := $(wildcard $(ANDROID_NDK_PATH)/toolchains/aarch64-linux-android-*/prebuilt/linux-x86_64/bin):$(PATH)

ALGK_PATH       = $(CURDIR)
ALGK_APK        = $(ALGK_PATH)/bin/algk-debug.apk
SYSROOT         = $(ANDROID_NDK_PATH)/platforms/android-23/arch-arm64
ECL_TO_RUN      = $(ECL_SRC_PATH)/ecl-android-host/bin/ecl
ECL_INSTALL_DIR = $(ECL_SRC_PATH)/ecl-android
ECL_LIB         = $(ECL_INSTALL_DIR)/lib/libecl.so

SWANK_FASL_DIR := $(shell HOME=$(ALGK_PATH) $(ECL_TO_RUN) -q --load $(SLIME_PATH)/swank-loader.lisp \
                          --eval '(progn (format t "~A" (swank-loader::default-fasl-dir)) (quit))')

SLIME_FASLS := $(addsuffix .fas, \
			   $(addprefix $(SWANK_FASL_DIR), \
				       backend ecl gray match packages rpc swank \
				       $(addprefix contrib/, \
						   swank-arglists swank-asdf swank-c-p-c \
						   swank-fancy-inspector swank-fuzzy swank-hyperdoc \
						   swank-macrostep swank-mrepl swank-package-fu \
						   swank-presentations swank-presentation-streams \
						   swank-quicklisp swank-repl swank-trace-dialog \
						   swank-util)))

FASB := alexandria.fasb \
	babel.fasb \
	bordeaux-threads.fasb \
	cffi.fasb \
	cl-autowrap.fasb \
	cl-json.fasb \
	cl-opengl.fasb \
	cl-plus-c.fasb \
	cl-ppcre.fasb \
	defpackage-plus.fasb \
	sdl2.fasb \
	trivial-channels.fasb \
	trivial-features.fasb \
	trivial-garbage.fasb \
	trivial-timeout.fasb

ALGK_FASLS := $(addprefix fasls/,$(FASB) $(notdir $(SLIME_FASLS)))

find_symbol = (find-symbol \"$(1)\" (find-package :$(2)))

where_is_system = $(ECL_TO_RUN) -q --eval "(progn (require :ecl-quicklisp) \
                                             (format t \"~A~%\" (funcall $(call find_symbol,WHERE-IS-SYSTEM,ql) :$(1))) \
                                             (quit))" | tail -n 1

all: $(ALGK_APK) $(ALGK_FASLS)

clean: 				#TODO Clean

$(ECL_SRC_PATH)/.patched: $(ALGK_PATH)/ecl-android-aarch64.patch
	cd $(ECL_SRC_PATH) && patch -p1 < $<
	touch $@

$(ECL_SRC_PATH)/.configured-host: $(ECL_SRC_PATH)/.patched
	cd $(ECL_SRC_PATH)/src && autoconf
	cd $(ECL_SRC_PATH) && ./configure CFLAGS="-g -O2" LDFLAGS="-g -O2" --prefix=$(ECL_SRC_PATH)/ecl-android-host
	touch $@

$(ECL_TO_RUN): $(ECL_SRC_PATH)/.configured-host
	$(MAKE) -C $(ECL_SRC_PATH)
	$(MAKE) -C $(ECL_SRC_PATH) install
	rm -rf $(ECL_SRC_PATH)/build

$(ECL_SRC_PATH)/.configured-target: $(ECL_TO_RUN)
	(export ECL_TO_RUN=$(ECL_TO_RUN); \
	 export LDFLAGS=--sysroot=$(SYSROOT); \
	 export CPPFLAGS=--sysroot=$(SYSROOT); \
	 cd $(ECL_SRC_PATH) && \
	 ./configure --host=aarch64-linux-android \
		     --prefix=$(ECL_INSTALL_DIR) \
		     --with-cross-config=$(ECL_SRC_PATH)/src/util/android.cross_config.aarch64)
	touch $@

$(ECL_LIB): $(ECL_SRC_PATH)/.configured-target
	$(MAKE) -C $(ECL_SRC_PATH)
	$(MAKE) -C $(ECL_SRC_PATH) install

$(addprefix fasls/,$(notdir $(SLIME_FASLS))): $(ECL_LIB) $(ALGK_PATH)/cross-compile-swank.lisp
	HOME=$(ALGK_PATH) $(ECL_TO_RUN) --eval \
	  "(progn \
	     (defvar *CMPDEFS* #P\"$(ECL_SRC_PATH)/build/cmp/cmpdefs\") \
	     (defvar *SWANK-LOADER* #P\"$(SLIME_PATH)/swank-loader\") \
	     (load \"$(ALGK_PATH)/cross-compile-swank.lisp\") \
	     (quit))"
	mkdir -p $(ALGK_PATH)/fasls
	cp -p $(SLIME_FASLS) $(ALGK_PATH)/fasls

# Do not know how to patch before compiling, so quickload twice
$(addprefix fasls/,$(FASB)): $(ECL_LIB)
	HOME=$(ALGK_PATH) $(ECL_TO_RUN) --eval "(progn (require :ecl-quicklisp)\
						  (funcall $(call find_symbol,QUICKLOAD,ql) \"cl-opengl\")\
						  (funcall $(call find_symbol,QUICKLOAD,ql) \"sdl2\")\
						  (quit))"
	cd `HOME=$(ALGK_PATH) $(call where_is_system,cl-opengl)` && patch -p1 <$(ALGK_PATH)/cl-opengl.patch
	cd `HOME=$(ALGK_PATH) $(call where_is_system,sdl2)` && patch -p1 <$(ALGK_PATH)/cl-sdl2.patch
	HOME=$(ALGK_PATH) $(ECL_TO_RUN) --eval "(progn (require :ecl-quicklisp)\
						  (funcall $(call find_symbol,QUICKLOAD,ql) \"cl-opengl\")\
						  (funcall $(call find_symbol,QUICKLOAD,ql) \"sdl2\")\
						  (quit))"
	HOME=$(ALGK_PATH) $(ECL_TO_RUN) --eval "(progn \
						  (load \"$(ECL_SRC_PATH)/build/cmp/cmpdefs.lsp\") \
						  (require :ecl-quicklisp) \
						  (let ((l $(call find_symbol,LOAD-SYSTEM,asdf))) \
						    (funcall l :cl-opengl) \
						    (funcall l :sdl2)) \
						  (macrolet \
						     ((redef-load-fasl () \
						       (let ((s $(call find_symbol,PERFORM-LISP-LOAD-FASL,asdf/lisp-action))) \
							 \`(defun ,s (o c))))) \
							 (redef-load-fasl)) \
						  (let ((c $(call find_symbol,COMPILE-SYSTEM,asdf)) \
							(m $(call find_symbol,MAKE-BUILD,asdf))) \
						    (pushnew :android *features*) \
						    (pushnew :arm64 *features*) \
						    (pushnew :aarch64 *features*) \
						    (setq *features* (delete :x86_64 *features*) \
							  *features* (delete :linux *features*)) \
						    (funcall c :cl-opengl :force :all) \
						    (funcall c :sdl2 :force :all) \
						    (funcall m :cl-opengl :type :fasl) \
						    (funcall m :sdl2 :type :fasl)) \
						  (quit))"
	mkdir -p $(ALGK_PATH)/fasls
	find $(ALGK_PATH)/.cache/common-lisp/ecl* \
	     \( $(subst $(lastword $(FASB)) -o,$(lastword $(FASB)),$(foreach fas,$(FASB), -name $(fas) -o)) \) \
	     -exec cp -pt $(ALGK_PATH)/fasls {} +

$(SDL2_SRC_PATH)/.patched: $(ALGK_PATH)/sdl2-android-aarch64.patch
	cd $(SDL2_SRC_PATH) && patch -p1 < $<
	touch $@

$(ALGK_PATH)/local.properties: $(SDL2_SRC_PATH)/.patched
	$(ANDROID_SDK_PATH)/tools/android update project --path . -t 1

$(ALGK_APK): $(ECL_LIB) $(ALGK_PATH)/local.properties
	ln -fs $(ECL_INSTALL_DIR)/include jni/src
	ln -fs $(ECL_LIB) jni/src
	ln -fs $(SDL2_SRC_PATH) jni/SDL
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(ANDROID_SDK_PATH) $(ANDROID_NDK_PATH)/ndk-build
	ant debug
