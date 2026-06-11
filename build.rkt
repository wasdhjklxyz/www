#lang racket

(require html-writing html-parsing markdown "css.rkt")

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

;; Headers
(define art-xexp
  `(header
     (pre (@ (class "art") (aria-hidden "true")) ,art)
     (h1 ,host)
     (small ,tagline)))

(define nav-xexp
  (let ([links (list (link "/#about" "about")
                     (link "/#articles" "articles")
                     (link "/#contact" "contact"))])
    `(nav ,(link "/" host)
          (div (@ (class "links")) ,@(add-between links "\n")))))

;; Page Skeleton
(define (page-xexp title description path . body)
  `(html (@ (lang "en"))
         ,(head-xexp title description path)
         ,@body
         ,(footer-xexp footer-links
                       (footer-license
                         "creativecommons.org/licenses/by-sa/4.0"
                         "CC BY-SA 4.0"))))

;; Markdown
(current-strict-markdown? #t)

(define (md->sxml path)
  (define xs (parse-markdown path))
  (define html-string (string-join (map xexpr->string xs) ""))
  (cdr (html->xexp html-string))) ; strip *TOP* wrapper

(define (article-xexp title path-str)
  `(article-xexp (@ (id ,title))
                 ,@(md->sxml (string->path path-str))))

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

(define (build-article foobar)
  (define foobar-path (string-append "articles/" foobar))
  (build (string-append foobar-path ".html")
         (page-xexp foobar tagline "/"
                    nav-xexp
                    (article-xexp foobar
                                  (string-append "./" foobar-path ".md")))))

;; Copy Assets
(for ([asset assets]
      #:when (or (file-exists? asset) (directory-exists? asset)))
  (copy-directory/files asset (build-path out-dir asset)))

;; Pages
(build "index.html"
       (page-xexp host tagline "/"
                  art-xexp
                  `(main
                     ,(article-xexp "about" "./articles/home/about.md")
                     ,(article-xexp "articles" "./articles/home/articles.md")
                     ,(article-xexp "contact" "./articles/home/contact.md")
                     ,(buttons-xexp my-buttons)
                     ,(buttons-xexp buttons))))

(build-article "name-origins")
