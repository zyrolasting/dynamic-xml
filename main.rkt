#lang racket/base

(require racket/contract)
(provide
 (contract-out [make-xexpr-proc (->* (symbol?) (#:always-show-attrs? boolean?) procedure?)]
               [kwargs->attributes (-> (listof keyword?) list? list?)]
               [apply-xexpr-element (->* (list?)
                                         ((-> symbol? procedure?)
                                          #:recurse? any/c)
                                         any/c)]))

(define (kwargs->attributes kws args)
  (map (λ (k v) (list (string->symbol (keyword->string k)) v)) kws args))

(define (make-xexpr-proc tag-name #:always-show-attrs? [asa #f])
  (make-keyword-procedure
   (λ (kws args . formals)
     (apply list
            tag-name
            (if (and (null? kws) (not asa))
                formals
                (cons (kwargs->attributes kws args) formals))))))

(define (attrs? maybe-attrs)
  (or (null? maybe-attrs)
      (list? (car maybe-attrs))))

(define (attrs->keyword-data attrs)
  (sort (map (λ (kv) (cons (string->keyword (symbol->string (car kv))) (cadr kv))) attrs)
        keyword<?
        #:key car))

(define-syntax-rule (fail-to-null expr)
  (with-handlers ([exn? (λ _ null)]) expr))

(define (apply-xexpr-element x
                             #:recurse? [recurse? #t]
                             [lookup make-xexpr-proc])
  (define maybe-attrs (fail-to-null (cadr x)))

  (define-values (kw-list kw-val-list formals)
    (if (attrs? maybe-attrs)
        (let ([sorted (attrs->keyword-data maybe-attrs)])
          (values (map car sorted) (map cdr sorted) (fail-to-null (cddr x))))
        (values null null (cdr x))))

  (define children
    (if recurse?
        (map (λ (el)
               (if (and (list? el) (not (null? el)))
                   (apply-xexpr-element el lookup #:recurse? #t)
                   el))
             formals)
        formals))

  (keyword-apply (lookup (car x)) kw-list kw-val-list children))

(module+ test
  (require rackunit)
  (test-case "make-xexpr-proc"
    (define e (make-xexpr-proc 'e))
    (define s (make-xexpr-proc 's))
    (check-equal? (e #:id "cool" (s "strings"))
                  '(e ((id "cool"))
                      (s "strings"))))

  (test-case "apply-xexpr-element"
    (test-equal? "By default, elements are reconstructed"
                 (apply-xexpr-element '(p ((id "a")) "foo"))
                 '(p ((id "a")) "foo"))
    (test-case "Can recurse to children"
      (define (proc . _)
       (make-keyword-procedure
        (λ (kws args . children)
          (unless (null? children)
            (check-equal? (car (car children)) 'p))
          `(p ,(kwargs->attributes kws args)))))
      (check-equal? (apply-xexpr-element '(e (e)) proc)
                    '(p ())))))
