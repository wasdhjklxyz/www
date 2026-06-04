#lang racket

(require html-writing "css.rkt")

;; Config
(define host    "wasdhjkl.xyz")
(define tagline "kernels / networking / offensive security / nix btw / nvim btw")
(define art     (file->string "art.txt"))
(define email   (string-append "uiop@" host))

;; Links
(define (link url label) `(a (@ (href ,url)) ,label))
(define (link-site site label) (link (string-append "https://" site) label))
(define (link-email email label) (link (string-append "mailto:" email) label))

;; Head
(define (head-xexp title description path)
  `(head
     (meta (@ (charset "utf-8")))
     (meta (@ (name "viewport")
              (content "width=device-width, initial-scale=1")))
     (meta (@ (name "description") (content ,description)))
     (meta (@ (name "theme-color") (content ,(symbol->string color-bg))))
     (link (@ (rel "canonical") (href ,(string-append "https://" host path))))
     (style ,css)
     (title ,title)))

;; Footer
(define footer-sep '(span (@ (class "sep")) " · "))

(define footer-links
  (list (link-site "github.com/wasdhjklxyz" "github")
        (link-site "x.com/wasdhjklxyz" "twitter")
        (link-email email "email")))

(define (footer-license site label)
  (link-site site (string-append "© 2026 uiop. Licensed under " label)))

(define (footer-xexp links license)
  `(footer ,@(add-between (append links (list license)) footer-sep)))

;; Page Skeleton
(define (page-xexp title description path . body-)
  `(html (@ (lang "en"))
     ,(head-xexp title description path)
     ,@body
     ,(footer-xexp footer-links
                   (footer-license
                     "creativecommons.org/licenses/by-sa/4.0"
                     "CC BY-SA 4.0"))))

;; Build
(define (build path xexp)
  (call-with-output-file path #:exists 'replace
                         (lambda (out)
                           (display "<!DOCTYPE html>" out)
                           (write-html xexp out))))

;; Pages
(build "index.html"
       (page-xexp host tagline "/"
                  `(header
                     (pre (@ (class "art") (aria-hidden "true")) ,art)
                     (h1 ,host)
                     (small ,tagline))
                  `(main (p "hello world"))))
