(in-package :generic-math-output-implementation)

(defparameter *continued-fraction-display-length* 5)

(def-mo-pres-type cf-ps:continued-fraction)

(def-math-output-prepare (cf-ps:continued-fraction)
  (finite-continued-fraction
   (append1
    (map 'list
         #'math-output-prepare
         (lazy-array-take (cf-ps:partial-quotients cf-ps:continued-fraction)
                          *continued-fraction-display-length*
                          nil))
    "...")))

;; provide error messages if we don't have a suitable gm:xxx method
;; for the given object
