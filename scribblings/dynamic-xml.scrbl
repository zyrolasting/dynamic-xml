#lang scribble/manual
@require[@for-label[racket/base
                    racket/contract
                    dynamic-xml
                    xml]]

@title{Translate X-Expressions to Keyword Procedure Applications}
@author{Sage Gerard}

@defmodule[dynamic-xml]

Nothing magical here. This small library provides the means to apply
keyword procedures in a given namespace using X-expressions. This is
useful for XML-based document processors that either want to support
custom elements, or transform existing elements.

@section{Reference}
@defproc[(apply-xexpr-element [x xexpr?]
                              [#:recurse? recurse? boolean? #t]
                              [ns namespace? (current-namespace)]
                              [fail-thunk (-> procedure?) (λ () (make-xexpr-proc (car x)))])
                              xexpr?]{
Let this element be bound to @racketfont{E}:

@racketblock[
'(p ((id "my-paragraph") (class "colorized"))
    (b "I am bold") "and I am bland.")
]

@racket[(apply-xexpr-element E #:recurse? #f)] is equivalent to the
following expression, as evaluated in @racket[ns]:

@racketblock[
(p #:id "my-paragraph"
   #:class "colorized"
   '(b ((style "color: #f00")) "I am bold")
   "and I am bland.")
]

When @racket[#:recurse?] is set to a true value, then the same
treatment applies to all descendent elements.

@racketblock[
(p #:id "my-paragraph"
   #:class "colorized"
   (b #:style "color: #f00" "I am bold")
   "and I am bland.")]

If an element's tag name does not appear in @racket[ns], then
@racket[apply-xexpr-element] will apply @racket[fail-thunk] to produce
an alternative procedure. The procedure returned from
@racket[fail-thunk] must accept keyword arguments and formal
parameters, such that the keyword arguments are equal to the
attributes defined in @racket[x], and the formal arguments are equal
to the children elements of @racket[x].

By default, @racket[fail-thunk] returns a procedure that merely
reassembles the arguments into an X-expression equivalent to
@racket[x] (See @racket[make-xexpr-proc]).
}

@defproc[(make-xexpr-proc [t symbol?]) procedure?]{
Returns a procedure that creates X-expressions with tag @racket[t].

Keyword arguments turn into the attribute list of the output element.
Formal arguments turn into children of said element.

@racketinput[
((make-xexpr-proc 'script) #:type "text/javascript" "function foo() { return 1 + 1; }")
]
@racketresult[
'(script ((type "text/javascript")) "function foo() { return 1 + 1; }")
]
}


@defproc[(kwargs->attributes [kws (listof keyword?)]
                             [kw-args list?])
                             list?]{
A helper procedure that translates keyword arguments into an X-expression attribute list.

@racketinput[(kwargs->attributes '(#:id #:style) '("ID" "color: #fff"))]
@racketresult['((id "ID") (style "color: #fff"))]
}


@section{Gotchas}
While I mention the @racket[xexpr?] predicate above, my contracts
don't actually use it. The cost of checking element trees add up
quickly, so I don't impose it.

Also, I use namespaces because I know how to avoid writing a long
dictionary. But this convenience comes at the cost of vulnerability to
naming collisions. For example, the HTML @tt{map} element will cause
@racket[apply-xexpr-element] to apply Racket's @racket[map]. Take care
to address this.
