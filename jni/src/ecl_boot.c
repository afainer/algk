#include <stdlib.h>
#include <ecl/ecl.h>
#include <SDL.h>

#define LOGI(...) SDL_LogInfo(SDL_LOG_CATEGORY_APPLICATION, __VA_ARGS__)

#include "ecl_boot.h"

#ifdef __cplusplus
#define ECL_CPP_TAG "C"
#else
#define ECL_CPP_TAG
#endif

int ecl_boot(const char *libdir, const char *home)
{
        char *ecl = "ecl";
        char tmp[2048];
        cl_object obj;

        LOGI("ECL boot beginning\n");

        LOGI("Setting directories: libdir => %s, home => %s\n", libdir, home);
        setenv("HOME", home, 1);

        sprintf(tmp, "%s/", libdir);
        setenv("ECLDIR", tmp, 1);

        sprintf(tmp, "%s/etc/", home);
        setenv("ETC", tmp, 1);

        LOGI("Directories set\n");

        cl_boot(1, &ecl);

        LOGI("installing bytecodes compiler\n");
        si_safe_eval(3, c_string_to_object("(si:install-bytecodes-compiler)"), ECL_NIL, OBJNULL);

        LOGI("logging some info\n");

        obj = si_coerce_to_base_string
          (si_safe_eval
           (3, c_string_to_object
            ("(format nil \"ECL_BOOT, features = ~A ~%\" *features*)"),
            Cnil, OBJNULL));

        LOGI("%s\n",
             (char *)obj->string.self);

        obj = si_coerce_to_base_string
          (si_safe_eval
           (3, c_string_to_object
            ("(format nil \"(truename SYS:): ~A)\" (truename \"SYS:\"))"),
            Cnil, OBJNULL));

        LOGI("%s\n", (char *) obj->string.self);

        ecl_toplevel(home);
        return 0;
}

void ecl_toplevel(const char *home)
{
        char tmp[2048];

        LOGI("Executing the init scripts\n");

        CL_CATCH_ALL_BEGIN(ecl_process_env())
        {
                sprintf(tmp, "(setq *default-pathname-defaults* #p\"%s/\")", home);
                si_safe_eval(3, c_string_to_object(tmp), Cnil, OBJNULL);
                si_select_package(ecl_make_simple_base_string("CL-USER", 7));
                si_safe_eval(3, c_string_to_object("(load \"etc/init\")"), Cnil, OBJNULL);
        } CL_CATCH_ALL_END;

        LOGI("Toplevel initialization done\n");
}
