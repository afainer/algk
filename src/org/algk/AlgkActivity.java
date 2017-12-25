package org.algk;

import android.os.*;
import org.libsdl.app.SDLActivity;

/**
 * A sample wrapper class that just calls SDLActivity
 */

public class AlgkActivity extends SDLActivity {

    @Override
    protected String[] getLibraries() {
        return new String[] {
            "SDL2",
            // "SDL2_image",
            // "SDL2_mixer",
            // "SDL2_net",
            // "SDL2_ttf",
            "ecl",
            "main"
        };
    }

    @Override
    protected String[] getArguments() {
        return new String[] {
            getApplicationInfo().nativeLibraryDir,
            getFilesDir().getAbsolutePath(),
            getExternalFilesDir(null).getAbsolutePath()
        };
    }
}
