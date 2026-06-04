#lang racket

(require html-writing "css.rkt")

;; Config
(define host    "wasdhjkl.xyz")
(define tagline "kernels / networking / offensive security / nix btw / nvim btw")
(define art     (file->string "art.txt"))
(define email   (string-append "uiop@" host))
(define out-dir "dist")
(define assets  (list "buttons" "favicon.ico"))

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

;; Section
(define (section-xexp title . content)
  `(section (@ (id ,title)) (h2 ,title) ,@content))

;; Buttons
(define (auto-href alt) ; If alt contains a . and no space auto link it
  (if (and (string-contains? alt ".")
           (not (string-contains? alt " ")))
      (string-append "https://" alt)
      #f))

(define (button src alt [href (auto-href alt)])
  (define img
    `(img (@ (src ,(string-append "/buttons/" src)) (alt ,alt))))
  (if href (link href img) img))

(define my-buttons
  (list (button "uiop1.png" "wasdhjkl.xyz")
        (button "uiop2.png" "wasdhjkl.xyz")))

(define buttons
  (list (button "neovim.gif"      "neovim.io")
        (button "nix.png"         "nixos.org")
        (button "IA.gif"          "archive.org")
        (button "ublock.png"      "ublockorigin.com")
        (button "upallnight.gif"  "up all night")
        (button "firefox4.gif"    "firefox.com")
        (button "cookie-free.png" "cookie free")
        (button "88x31.gif"       "88x31.nl")
        (button "lain.gif"        "lain" "https://en.wikipedia.org/wiki/Serial_Experiments_Lain")
        (button "hasmile.gif"     "have a smile")
        (button "by-sa.png"       "creativecommons.org/licenses/by-sa/4.0")))

(define (buttons-xexp buttons)
  `(div (@ (class "buttons")) ,@buttons))

;; Page Skeleton
(define (page-xexp title description path . body)
  `(html (@ (lang "en"))
     ,(head-xexp title description path)
     ,@body
     ,(footer-xexp footer-links
                   (footer-license
                     "creativecommons.org/licenses/by-sa/4.0"
                     "CC BY-SA 4.0"))))

;; Build
(when (directory-exists? out-dir) (delete-directory/files out-dir))
(make-directory* out-dir)

(define (build rel xexp)
  (define path (build-path out-dir rel))
  (make-directory* (path-only path))
  (call-with-output-file path #:exists 'replace
                         (lambda (out)
                           (display "<!DOCTYPE html>" out)
                           (write-html xexp out))))

;; Copy Assets
(for ([asset assets]
      #:when (or (file-exists? asset) (directory-exists? asset)))
  (copy-directory/files asset (build-path out-dir asset)))

;; Pages
(build "index.html"
       (page-xexp host tagline "/"
                  `(header
                     (pre (@ (class "art") (aria-hidden "true")) ,art)
                     (h1 ,host)
                     (small ,tagline))
                  `(main
                     ,(section-xexp "about" '(p "hello world"))
                     ,(section-xexp "blog" '(p "hello world"))
                     ,(section-xexp "projects" '(p "hello world"))
                     ,(section-xexp "contact" '(p "hello world"))
                     ,(buttons-xexp my-buttons)
                     ,(buttons-xexp buttons))))
