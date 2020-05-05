#lang scribble/manual
@require[@for-label[racket/base
                    racket/contract
                    dynamic-xml
                    xml]]

@title{Translate X-Expressions to Keyword Procedure Applications}
@author{Sage Gerard}

@defmodule[dynamic-xml]

This small library provides the means to apply keyword procedures
using X-expressions. This is useful for XML-based document processors
that either want to support custom elements, or transform existing
elements.

@bold{Beware:} While I mention the @racket[xexpr?] predicate below, my
contracts don't actually use it. The cost of checking element trees
add up quickly, so I don't impose it.

@section{Reference}
@defproc[(apply-xexpr-element [x xexpr?]
                              [#:recurse? recurse? boolean? #t]
                              [lookup (-> symbol? procedure?) make-xexpr-proc])
                              xexpr?]{
Let this element be bound to @racketfont{E}:

@racketblock[
'(p ((id "my-paragraph") (class "colorized"))
    (b "I am bold") "and I am bland.")
]

@racket[(apply-xexpr-element E #:recurse? #f)] is equivalent to the
following expression:

@racketblock[
((lookup 'p) #:id "my-paragraph"
             #:class "colorized"
             '(b ((style "color: #f00")) "I am bold")
             "and I am bland.")
]

When @racket[#:recurse?] is set to a true value, then the same
treatment applies to all descendent elements.


@racketblock[
((lookup 'p) #:id "my-paragraph"
             #:class "colorized"
             ((lookup 'b) #:style "color: #f00" "I am bold")
             "and I am bland.")]

@racket[(apply-xexpr-element #:recurse? #t E make-xexpr-proc)] will
return an X-expression equivalent to @racket[E], except attributes
will match the @racket[keyword<?] ordering imposed by an internal use
of @racket[keyword-apply], and empty attribute lists will be removed
from the output. To adjust the latter behavior, bind @racket[lookup] to a
different use of @racket[make-xexpr-proc].
}

@defproc[(make-xexpr-proc [t symbol?]
                          [#:always-show-attrs? show-attrs any/c #f])
                          procedure?]{
Returns a procedure that creates X-expressions with tag @racket[t].

Keyword arguments turn into the attribute list of the output element.
Formal arguments turn into children of said element.

If the element has no attributes, then no attribute
list will appear in the output X-expression unless
@racket[show-attrs] is a true value.

@racketinput[
((make-xexpr-proc 'script) #:type "text/javascript" "function foo() { return 1 + 1; }")
]
@racketresult[
'(script ((type "text/javascript")) "function foo() { return 1 + 1; }")
]

@racketinput[
((make-xexpr-proc #:always-show-attrs? #t 'p) "hi")
]
@racketresult[
'(p () "hi")
]
}

@defproc[(kwargs->attributes [kws (listof keyword?)]
                             [kw-args list?])
                             list?]{

A helper procedure that translates keyword arguments into an X-expression attribute list.
The attributes follow the order of @racket[kws] and @racket[kw-args].

@racketinput[(kwargs->attributes '(#:id #:style) '("ID" "color: #fff"))]
@racketresult['((id "ID") (style "color: #fff"))]
}
