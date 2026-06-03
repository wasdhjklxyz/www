#lang racket

(provide html-head html-footer)

(require html-template)

(define host    "wasdhjkl.xyz")
(define tagline "kernels / networking / offensive security / nix btw / nvim btw")

(define (html-head #:css css
                   #:theme-color theme-color)
  (html-template
    (head
      (meta (@ (charset "utf-8")))
      (meta (@ (name "viewport")
               (content "width=device-width, initial-scale=1")))
      (meta (@ (name "description")
               (content (% tagline))))
      (meta (@ (name "theme-color")
               (content (% (symbol->string theme-color)))))
      (link (@ (rel "canonical")
               (href (% (string-append "https://" host)))))
      (style (% css))
      (title (% host)))))

(define html-footer
  (html-template
    (footer
      (a (@ (href "https://github.com/wasdhjklxyz")) "github" )
      (span (@ (class "sep")))
      (a (@ (href "https://x.com/wasdhjklxyz")) "twitter" )
      (span (@ (class "sep")))
      (a (@ (href "mailto://uiop@wasdhjkl.xyz")) "email" )
      (span (@ (class "sep")))
      (a (@ (href "https://creativecommons.org/licenses/by-sa/4.0"))
         "© 2026 uiop. Licensed under CC BY-SA 4.0"))))
