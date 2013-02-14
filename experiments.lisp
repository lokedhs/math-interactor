(in-package :math-interactor)

;;; some tests and examples of the math-interactor

(define-math-interactor-command (com-output-test :menu t :name "Ausgabe testen")
    ()
  (let ((stream (get-frame-pane *application-frame* 'app)))
    (format stream "~&Hallo~%")))

(defun define-example% (math-object)
  (let ((stream (get-frame-pane *application-frame* 'app)))
    (stream-add-math-output stream
                            (math-output math-object stream)
                            :line-break t)
    (stream-replay stream)))

(defmacro! define-example (name math-object-spec)
  `(define-math-interactor-command (,(symb 'com- (string-upcase name)) :menu t :name ,name)
       ()
     (define-example% ,math-object-spec)))


(define-example "Bruch anzeigen"
    (fraction 12312347
              123894))

(define-example "Summe anzeigen"
    (finite-sum (list 1 2 3 4 5 6
                      (fraction 17 1329846))))

(define-example  "Kettenbruch anzeigen"
    (make-instance 'finite-continued-fraction
                   :partial-quotients (list 1 2 3 4 5 6 7)))

