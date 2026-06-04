#lang at-exp racket

(provide about-xexp)

(require "../article.rkt")

(define about-xexp
  (article
    "about"
    @p{Hello! I'm uiop. I own three Thinkpads.}
    @p{This is another line with a @a["https://wasdhjkl.xyz"]{link}.}
    @i{another line?!}))
