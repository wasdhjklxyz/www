#lang racket

(require "css.rkt")
(require html-template)

(define host    "wasdhjkl.xyz")
(define tagline "kernels / networking / offensive security / nix btw / nvim btw")

(define html-head
  (html-template
    (head
      (meta (@ (charset "utf-8")))
      (meta (@ (name "viewport")
               (content "width=device-width, initial-scale=1")))
      (meta (@ (name "description")
               (content (% tagline))))
      (meta (@ (name "theme-color")
               (content (% (symbol->string color-bg)))))
      (link (@ (rel "canonical")
               (href (% (string-append "https://" host)))))
      (style (% css))
      (title (% host)))))

(display html-head)
