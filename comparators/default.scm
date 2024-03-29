;;;; SPDX-FileCopyrightText: 2013 John Cowan <cowan@ccil.org>
;;;;
;;;; SPDX-License-Identifier: MIT

;;; The default comparator

;; The unknown-object comparator, used as a fallback to everything else
(define unknown-object-comparator
  (make-comparator
    (lambda (obj) #t)
    (lambda (a b) #t)
    (lambda (a b) 0)
    (lambda (obj) 0)))

;; Next index for added comparator

(define first-comparator-index 9)
(define *next-comparator-index* 9)
(define *registered-comparators* (list unknown-object-comparator))

;; Register a new comparator for use by the default comparator.
(define (comparator-register-default! comparator)
  (set! *registered-comparators* (cons comparator *registered-comparators*))
  (set! *next-comparator-index* (+ *next-comparator-index* 1)))

;; Return ordinal for object types: null sorts before pairs, which sort
;; before booleans, etc.  Implementations can extend this.
;; People who call comparator-register-default! effectively do extend it.
(define (object-type obj)
  (cond
    ((null? obj) 0)
    ((pair? obj) 1)
    ((boolean? obj) 2)
    ((char? obj) 3)
    ((string? obj) 4)
    ((symbol? obj) 5)
    ((number? obj) 6)
    ((vector? obj) 7)
    ((bytevector? obj) 8)
    ; Add more here if you want: be sure to update comparator-index variables
    (else (registered-index obj))))

;; Return the index for the registered type of obj.
(define (registered-index obj)
  (let loop ((i 0) (registry *registered-comparators*))
    (cond
      ((null? registry) (+ first-comparator-index i))
      ((comparator-test-type (car registry) obj) (+ first-comparator-index i))
      (else (loop (+ i 1) (cdr registry))))))

;; Given an index, retrieve a registered conductor.
;; Index must be >= first-comparator-index.
(define (registered-comparator i)
  (list-ref *registered-comparators* (- i first-comparator-index)))

(define (dispatch-equality type a b)
  (case type
    ((0) 0) ; All empty lists are equal
    ((1) (= (pair-comparison a b) 0))
    ((2) (= (boolean-comparison a b) 0))
    ((3) (= (char-comparison a b) 0))
    ((4) (= (string-comparison a b) 0))
    ((5) (= (symbol-comparison a b) 0))
    ((6) (= (complex-comparison a b) 0))
    ((7) (= (vector-comparison a b) 0))
    ((8) (= (bytevector-comparison a b) 0))
    ; Add more here
    (else (comparator-equal? (registered-comparator type) a b))))

(define (dispatch-comparison type a b)
  (case type
    ((0) 0) ; All empty lists are equal
    ((1) (pair-comparison a b))
    ((2) (boolean-comparison a b))
    ((3) (char-comparison a b))
    ((4) (string-comparison a b))
    ((5) (symbol-comparison a b))
    ((6) (complex-comparison a b))
    ((7) (vector-comparison a b))
    ((8) (bytevector-comparison a b))
    ; Add more here
    (else (comparator-compare (registered-comparator type) a b))))

(define (default-hash-function obj)
  (case (object-type obj)
    ((0) 0)
    ((1) (pair-hash obj))
    ((2) (boolean-hash obj))
    ((3) (char-hash obj))
    ((4) (string-hash obj))
    ((5) (symbol-hash obj))
    ((6) (number-hash obj))
    ((7) (vector-hash obj))
    ((8) (bytevector-hash obj))
    ; Add more here
    (else (comparator-hash (registered-comparator (object-type obj)) obj))))

(define (default-comparison a b)
  (let ((a-type (object-type a))
        (b-type (object-type b)))
    (cond
      ((< a-type b-type) -1)
      ((> a-type b-type) 1)
      (else (dispatch-comparison a-type a b)))))

(define (default-equality a b)
  (let ((a-type (object-type a))
        (b-type (object-type b)))
    (if (= a-type b-type) (dispatch-equality a-type a b) #f)))

(define default-comparator
  (make-comparator
    #t
    default-equality
    default-comparison
    default-hash-function))

