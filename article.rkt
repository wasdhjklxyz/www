#lang racket

(provide p i a article)

(require html-writing)

(define (p . body) `(p ,@body))
(define (i . body) `(i ,@body))
(define (a url . body) `(a (@ (href ,url)) ,@body)) ; @a["url"]{label}

(define (article title . content)
  `(article (@ (id ,title)) (h2 ,title) ,@content))
