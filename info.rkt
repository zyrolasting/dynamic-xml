#lang info
(define collection "dynamic-xml")
(define deps '("base" "xml"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/dynamic-xml.scrbl" ())))
(define pkg-desc "Translate X-expressions into keyword procedure applications")
(define version "0.0")
(define pkg-authors '(sage))
