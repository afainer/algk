(load *CMPDEFS*)
(require 'cmp)
(load *SWANK-LOADER*)

(in-package :swank-loader)

(dolist (s (src-files *swank-files* *source-directory*))
  (load s))

(with-compilation-unit ()
  (compile-files (src-files *swank-files* *source-directory*)
                 *fasl-directory* nil nil))

(dolist (s (src-files *contribs* (contrib-dir *source-directory*)))
  (load s))

(compile-contribs)

;;; cp -p ~/.slime/fasl/2.19/ecl-16.1.3-linux-x86_64/{,contrib/}* dst
