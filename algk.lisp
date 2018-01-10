(defpackage #:algk
    (:use #:common-lisp #:trivial-channels)
    (:import-from #:alexandria #:with-gensyms)
    (:export #:*window* #:in-algk-thread #:algk-loop))

(in-package #:algk)

(setf cl-opengl-bindings::*gl-get-proc-address* #'cffi:foreign-symbol-pointer)

(cffi:define-foreign-library sdl2 (t "libSDL2.so"))
(cffi:use-foreign-library sdl2)

(cffi:define-foreign-library main (t "libmain.so"))
(cffi:use-foreign-library main)

(defvar *window* (sdl2:create-window :title "ALGK"
                                     :x 0 :y 0 :w 0 :h 0
                                     :flags '(:opengl)))

(defvar *gl-context* (sdl2:gl-create-context *window*))

(defvar *channel* (make-channel))
(defvar *thread* nil)

(defmacro in-algk-thread ((&key background) &body b)
  (with-gensyms (fun channel)
    `(let ((,fun (lambda () ,@b)))
       (if (or *channel* *thread*)
           (if *thread*
               (funcall ,fun)
               ,(if background
                    `(progn
                       (sendmsg *channel* (cons ,fun nil))
                       (values))
                    `(let ((,channel (make-channel)))
                       (sendmsg *channel* (cons ,fun ,channel))
                       (let ((result (recvmsg ,channel)))
                         (etypecase result
                           (list (values-list result))
                           (error (error result)))))))
           (error "No ALGK thread or channel")))))

(defun algk-loop ()
  (let ((*thread* (bt:current-thread))
        (swank:*sldb-quit-restart* 'abort))
    (loop while *channel* do
         (destructuring-bind (fun . chan) (recvmsg *channel*)
           (if chan
               (sendmsg chan
                        (handler-case (multiple-value-list
                                       (funcall fun))
                          (error (c) c)))
               (ignore-errors (funcall fun)))))))
