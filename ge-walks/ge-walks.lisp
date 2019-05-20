;; GE-walks... "greater-than-or-equal random walks"

;; ge(n,sigma) == # of random walks of length n that
;; do not drop below level sigma (starting at 0)...
(defstruct ge n sigma mult)

;; we'll work with a walk that moves +/- 1 each step, but this
;; is configurable if we want to play with other configurations
(defparameter *moves* (list -1 1)) 
(defparameter *min-u* (apply #'min *moves*))
(defparameter *len-u* (length *moves*))

(defun simplify (ge)
  "convert a ge(n,_) into a list of ge(n-1,_)'s -- or short-circuit
directly to an answer if possible."
  (let ((n (ge-n ge))
	(sigma (ge-sigma ge))
	(mult (ge-mult ge)))
    (cond ((> sigma 0)
	   ;; sigma < 0 is always a failure
	   0)
	  ((= n 0)
	   ;; n == 0, we get mult successes
	   mult)
	  ((>= (* n *min-u*) sigma)
	   ;; n*min >= sigma == we get
	   (* mult (expt *len-u* n)))
	  (t
	   ;; expand the current ge into two...
	   (mapcar #'(lambda (u)
		       (make-ge :n (1- n) :sigma (- sigma u) :mult mult))
		   *moves*)))))

(defun ge< (a b)
  "an ordering function on ge's, for sorting"
  (or (< (ge-n a) (ge-n b))
      (< (ge-sigma a) (ge-sigma b))))

(defun combine-like (list)
  "take a sorted list of ge's, and combine entries with the
same n and sigma values"
  (let ((result nil)
	(last-n -1)
	(last-sigma -1))
    (dolist (ge list result)
      (let ((n (ge-n ge))
	    (sigma (ge-sigma ge)))
	(if (and (= last-n n)
		 (= last-sigma sigma))
	    (setf (ge-mult (car result)) (+ (ge-mult ge) (ge-mult (car result))))
	    (progn
	      (setq last-n n last-sigma sigma)
	      (push ge result)))))))

(defun calc-ge (n sigma)
  "Count the number of random paths in ge(n,sigma). These are the
random walks that start a 0 and never fall below sigma in n steps."
  (loop
     :for ge-list = (list (make-ge :n n :sigma sigma :mult 1)) :then exps
     :until (null ge-list)
     :for (accum . exps) =
       (loop :for ge :in (mapcar #'simplify ge-list)
	  :if (consp ge) :nconc ge :into expansions
	  :else :summing ge :into sums
	  :finally (return (cons sums (combine-like (sort expansions #'ge<)))))
     :summing accum))

;; example use: random walks of length 6000 which don't drop
;; below zero:
;;(calc-ge 6000 0) =>
;;  155890742141154818804581673415655110590561891575242574042487
;;  706371324721240671547339307660956404020160841620785414309343
;;  292060735232186254403851038391051504508184385531849554555653
;;  266030783413416494487997526663092165538781318464573482553405
;;  121340811940642126257084085334122788675697357398106411575841
;;  399021746079766114869247799118343900559471911630288890204977
;;  389791987064859928070071015982046616906432559961303691065613
;;  795513146718994286572930558491059895431838467692652146350306
;;  290983893569437604219094802314458748196459507472435620417399
;;  072807841365771128245526187495172074547245514856585542708355
;;  975218665371884810357661532172893597311152168394260157175729
;;  118609868106218567432648118419595281607947404728627143563499
;;  578964801845174526539901059787101826953007943501298115104783
;;  157658073643076100395280976059505040626517811788180917209076
;;  874040430678804044740381180755484709826715866824745594397132
;;  199570775834390810927995761236355687496225164719455176875335
;;  556843051387284978333876433521838389330131777319029151537669
;;  316939499288272506723342008945577557248067844774233539301432
;;  133873468996338711288824365115313962901847948868518476269765
;;  722168391745200575185429625093160791548902470053914153093973
;;  712298626282876798733716570867119944046553175523442756181286
;;  656115995221046012645950604368314566942068111596365002901734
;;  444573064522116368150042932208027183001092717189643845475072
;;  776900273090172466632003219059029506559925400866880574754079
;;  304622060377544113856092857975877372140527096173631634245140
;;  607605465095573082407417205968558708433954814093645821580354
;;  818572179395595398139724118722884935462733835650274704487430
;;  074373809562626295008870255534848993382150584136976125160153
;;  230743619739835573180307184740435205471845806505303785759004
;;  986424443737612581719717310101513014272317442632175688014895
;;  45600
