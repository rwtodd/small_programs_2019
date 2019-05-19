;; just some code to play with surreal numbers
;; based on reading the Knuth book

;; a surreal number has two lists of (previously-defined) surreal numbers,
;; the "left set" and the "right set"
(defstruct (surreal (:conc-name) (:constructor sur (lset rset)))
  (lset nil :type list)
  (rset nil :type list))

;; surreal numbers are the same if they have matching lsets and rsets
(defun sur-identical (a b)
  (and (= (length (lset a)) (length (lset b)))
       (= (length (rset a)) (length (rset b)))
       (every #'sur= (lset a) (lset b))
       (every #'sur= (rset a) (rset b))))

;; here are the first two "days" of surreal numbers
(defconstant +S0+ (sur nil nil))
(defconstant +S1+  (sur (list +S0+) nil))
(defconstant +S-1+ (sur nil (list +S0+)))

;; let's format surreal numbers...
;; to match where I am in the book, I'll special case
;; 0, 1, and -1 so that it prints a little nicer...
(defun sur->str (sur)
  "format the surreal number"
  (cond
    ((sur-identical sur +S0+) "0")
    ((sur-identical sur +S1+) "1")
    ((sur-identical sur +S-1+) "-")
    (t (flet ((fmt-side (side)
		(if (null side)
		    ""
		    (format nil "~{~a~^,~}"
			    (mapcar #'sur->str side)))))
	 (format nil "<~a:~a>"  (fmt-side (lset sur)) (fmt-side (rset sur)))))))

;; how to tell when a surreal number is <= another...
(defun sur<= (a b)
  (and (every (lambda (al) (not (sur<= b al))) (lset a))
       (every (lambda (br) (not (sur<= br a))) (rset b))))

(defun sur< (a b)
  "a < b iff (not (b <= a))"
  (not (sur<= b a)))

;; a surreal number isn't proper unless every member of lset is <
;; every member of rset
(defun sur-properp (n)
  (every (lambda (l)
	   (every (lambda (r) (sur< l r))
		  (rset n)))
	 (lset n)))

;; surreal numbers are equivalent if they are both <= and >= each other...
(defun sur= (a b)
  (and (sur<= a b)
       (sur<= b a)))

(defun day-total (n)
  "There are 2^n-1 numbers at the end of each day"
  (1- (expt 2 n)))
