(in-package #:cl-user)

(defvar *swank-fasls* '(packages
                        backend
                        ecl
                        gray
                        match
                        rpc
                        swank
                        swank-util
                        swank-repl
                        swank-c-p-c
                        swank-arglists
                        swank-fuzzy
                        swank-fancy-inspector
                        swank-presentations
                        swank-presentation-streams
                        swank-asdf
                        swank-package-fu
                        swank-hyperdoc
                        swank-mrepl
                        swank-trace-dialog
                        swank-macrostep
                        swank-quicklisp))

(defvar *fasl-dir* (truename #P"SYS:"))

(dolist (f *swank-fasls*)
  (load (make-pathname
         :directory (pathname-directory *fasl-dir*)
         :name (string-downcase f)
         :type "fas"
         :defaults *fasl-dir*)))

(defun search-local-systems (name)
  (let ((str (string-downcase name)))
    (car (directory (merge-pathnames
                     (pathname
                      (concatenate 'string
                                   str "*/" str ".asd"))
                     (user-homedir-pathname))))))

(setf asdf:*system-definition-search-functions*
      (append asdf:*system-definition-search-functions*
              (list 'search-local-systems)))

(in-package #:swank/backend)
(defimplementation lisp-implementation-program ()
  "Return the argv[0] of the running Lisp process, or NIL."
  "org.lisp.ecl")

(in-package #:cl-user)

(mp:process-run-function "SLIME-listener"
                         #'(lambda ()
                             (swank:create-server :interface "0.0.0.0")))

(loop)
