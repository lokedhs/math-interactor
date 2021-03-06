(in-package :math-interactor)

(define-application-frame math-interactor ()
  ((formatted-content :initform (list (list 'app)
                                      (list 'bin))))
  (:menu-bar menubar-cmds)
  (:panes (app :application
               :width 800 :height 600
               :incremental-redisplay t
               :scroll-bars t)
          (int :interactor
               :width 800 :height 200)
          (bin :application
               :width 200 :height 500
               :incremental-redisplay t
               :scroll-bars t))
  (:layouts (default
                (vertically ()
                  (horizontally ()
                    bin
                    app)
                  int))))

(defun math-interactor ()
  "Start an interactive CLIM app that allows to manipulate polynomials
and continued fractions of power series."
  (run-frame-top-level (make-instance 'math-interactor)))

;; define a command to exit
(define-math-interactor-command (com-quit :name "Quit") ()
  (frame-exit *application-frame*)
  (clear-formatted 'app)
  (clear-formatted 'bin))

;;; hook system that allows loading data into the bin.
(defparameter *math-interactor-load-data-hooks* nil)

(defun add-mi-hook (fn)
  (pushnew fn *math-interactor-load-data-hooks*))

(define-math-interactor-command (com-run-hooks :name "Load data")
    ()
  ;; remove old displayed stuff
  (window-clear (get-frame-pane *application-frame* 'bin))
  ;; show anything stored in the *BIN* again
  (mapc #'funcall (reverse *math-interactor-load-data-hooks*)))

;;; manage content displayed in the app and bin window
(defvar *bin* nil
  "keep track of stored stuff in the bin, so complicated expressions
  don't have to be entered over and over again.")

;;; todo this should belong to the application frame


(defun clear-formatted (pane-id)
  (setf (cdr (assoc pane-id (slot-value *application-frame* 'formatted-content))) nil))

(defun get-formatted (pane-id)
  (reverse (assoc1 pane-id (slot-value *application-frame* 'formatted-content))))

(defun put-formatted (obj pane-id)
  (let ((fc (assoc pane-id (slot-value *application-frame* 'formatted-content))))
    (push obj (cdr fc))))

;;; math output helper functions
(defun put-result% (math-object pane-id)
  "Given a `math-object', produce a CLIM rendering of it and just
append it to the desired pane identified with `pane-id'."
  (let ((stream (get-frame-pane *application-frame* pane-id))
        (formatted-object (if (mft:formatted-p math-object) math-object
                              (math-utils-format:format-pretty
                               math-object :presentations t)))
        output-record)
    ;; TODO what about primitive stuff? should we worry about it?
    (put-formatted formatted-object pane-id)
    (with-output-recording-options (stream :draw nil)
      (setf output-record (rtc:render formatted-object stream))
      (rtc:advance-cursor output-record stream :line-break t))
    #|(stream-replay stream)|#
    ;; refresh entire window to also recompute bounding borders
    ;; (otherwise, we might get clipping if scrolling is on)
    (window-refresh stream)))

(defun put-result (math-object &optional to-bin)
  "Given an `math-object', produce a rendering and by default display
it in the app. If `to-bin' is true, add it to the bin and display it
there."
  (if (not to-bin)
      (put-result% math-object 'app)
      (unless (member math-object *bin* :test #'gm:=)
        (push math-object *bin*)
        (put-result% math-object 'bin))))

(defmacro put-result/formula (math-objects formula)
  "Render a `formula', which may contain the given `math-objects' to
the app pane. See also `formula-with-math-objects'."
  `(put-result% (formula-with-math-objects ,math-objects ,formula) 'app))

;; load stuff from bin on making new window
(defun populate-from-bin ()
  "(Re)Display content of `*bin*' in the bin."
  (dolist (mo (reverse *bin*))
    (put-result% mo 'bin)))

(add-mi-hook 'populate-from-bin)

;;; commands for moving stuff between the app and the bin, and
;;; clearing those.
(define-math-interactor-command (com-put-to-bin :name "Copy to bin")
    ((object 'interactive-object))
  (put-result object t))

(define-math-interactor-command (com-put-to-app :name "Copy to app")
    ((object 'interactive-object))
  (put-result object))

(define-math-interactor-command (com-clear-bin :name "Clear bin")
    ()
  (setf *bin* nil)
  (clear-formatted 'bin)
  (window-clear (get-frame-pane *application-frame* 'bin)))

(define-math-interactor-command (com-clear-app :name "Clear app")
    ()
  (clear-formatted 'app)
  (window-clear (get-frame-pane *application-frame* 'app)))

;; input of polynomials
(define-math-interactor-command (com-enter-polynomial :name t)
    ((coeff-string 'string :prompt "coefficients"))
  ;; TODO make polynomial input less hackish
  (let ((coeffs (read-from-string (concatenate 'string "(" coeff-string ")"))))
    (if (length=1 coeffs)
        (put-result (first coeffs))
        (put-result (apply #'polynomials:make-polynomial coeffs)))))

;;; 
(define-math-interactor-command (com-series-term :name "Set series output precision")
    ((additional-terms 'integer :default 5 :prompt "nr of additional terms"))
  #|(setf polynomial-series-printing:print-additional-terms
        additional-terms)|#
  (format (get-frame-pane *application-frame* 'int)
          "~&Show ~A negative coefficients of laurent series.~%"
          additional-terms))

(defmacros! def-int-disp-com (key &optional argument)
  `(define-math-interactor-command (,(symb 'com-integer-display- key))
       ,(if argument `((,argument ',argument)))
     (setf math-utils-format:*integer-display* ,(or argument key))))

(def-int-disp-com
    :standard
    :factorise
  (:factorise-over-s integer)
  :abbrev
  :abbrev+)

;; TODO allow exporting the app view of the math-interactor to TeX or something.

;; TODO allow direct input of polynomials as parameters, not just by
;; clicking on presentations.
