#lang racket

(require html-writing html-parsing markdown srfi/19 "css.rkt")

;; Config
(define host    "wasdhjkl.xyz")
(define tagline "kernels / networking / offensive security / nix btw / nvim btw")
(define art     (file->string "art.txt"))
(define email   (string-append "uiop@" host))
(define out-dir "./")
(define assets  (list "buttons" "favicon.ico"))
(define blog-dir "blog")
(define content-file "_index.md")

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
     (link (@ (rel "preconnect") (href "https://fonts.googleapis.com")))
     (link (@ (rel "preconnect")
              (href "https://fonts.gstatic.com")
              (crossorigin)))
     (link (@ (href "https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300..700&display=swap")
              (rel "stylesheet")))
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
(define header-xexp
  `(header
     (pre (@ (class "art") (aria-hidden "true")) ,art)
     (big ,host)))

(define nav-xexp
  (let ([links (list (link "/#about" "about")
                     (link "/#blog" "blog")
                     (link "/#contact" "contact"))])
    `(nav
       (a (@ (href "/") (style "color: transparent"))
          (pre (@ (class "art") (aria-hidden "true")) ,art))
       (div (@ (class "links"))
            (span ,host)
            (div
              ,@(add-between links ""))))))

;; Page Skeleton
(define (page-xexp title description path . body)
  `(html (@ (lang "en"))
         ,(head-xexp title description path)
         ,@body
         (div (@ (class "buttons-border")))
         ,(buttons-xexp my-buttons)
         ,(buttons-xexp buttons)
         ,(footer-xexp footer-links
                       (footer-license
                         "creativecommons.org/licenses/by-sa/4.0"
                         "CC BY-SA 4.0"))))

;; Markdown
;(current-strict-markdown? #t)

(define (node-text x)
  (cond
    [(string? x) x]
    [(pair? x)
     (apply string-append
            (map node-text
                 (filter (lambda (c) (not (and (pair? c) (eq? (car c) '@))))
                         (cdr x))))]
    [else ""]))

(define (find-first tag nodes)
  (for/or ([n (in-list nodes)])
    (and (pair? n)
         (if (eq? (car n) tag)
             n
             (find-first tag (filter pair? (cdr n)))))))

(define (attr node name)
  (and (pair? node)
       (pair? (cdr node))
       (pair? (cadr node))
       (eq? (car (cadr node)) '@)
       (let ([p (assq name (cdr (cadr node)))])
         (and p (cadr p)))))

(define (slugify s)
  (string-trim (regexp-replace* #rx"[^a-z0-9]+" (string-downcase s) "-") "-"))

(define (heading? x)
  (and (pair? x) (memq (car x) '(h2 h3 h4))))

(define (link-heading h)
  (define children
    (if (and (pair? (cdr h)) (pair? (cadr h)) (eq? (caadr h) '@))
        (cddr h)
        (cdr h)))
  (define slug (slugify (node-text h)))
  `(,(car h) (@ (id ,slug))
             (a (@ (href ,(string-append "#" slug))) ,@children)))

(define (md->sxml path)
  (define p (if (path? path) path (string->path path)))
  (define xs (parse-markdown p))
  (define html-string (string-join (map xexpr->string xs) ""))
  (define nodes (cdr (html->xexp html-string)))
  (map (lambda (n) (cond [(heading? n) (link-heading n)]
                         [(code-block? n) (highlight-block n)]
                         [else n])) nodes))

(define (section-xexp id . nodes)
  `(section (@ (id ,id)) ,@nodes))

;; Code Highlighter
(define (code-block? x) ; (pre (@ (class "brush: LANG")) (code ...))
  (and (pair? x) (eq? (car x) 'pre)
       (let ([c (attr x 'class)])
         (and c (string-prefix? c "brush: ")))))

(define (pygmentize code lang)
  (define-values (proc out in _err)
    (subprocess #f #f #f (find-executable-path "pygmentize")
                "-l" lang "-f" "html"))
  (write-string code in)
  (close-output-port in)
  (define result (port->string out))
  (subprocess-wait proc)
  (and (zero? (subprocess-status proc)) result))

(define (highlight-block pre)
  (define lang (substring (attr pre 'class) 7)) ; drop "brush: "
  (define html (pygmentize (node-text pre) lang))
  (if html
      (findf pair? (cdr (html->xexp html))) ; the <div class="highlight">
      pre)) ; lexer failed -> leave plain

;; Build
;(when (directory-exists? out-dir) (delete-directory/files out-dir))
;(make-directory* out-dir)

(define (build rel xexp)
  (define path (build-path out-dir rel))
  ;(make-directory* (path-only path))
  (call-with-output-file path #:exists 'replace
                         (lambda (out)
                           (display "<!DOCTYPE html>" out)
                           (write-html xexp out))))

(define (build-blog slug nodes)
  (define src-dir (build-path blog-dir slug))
  (define out-rel (build-path "blog" slug))
  (build (build-path out-rel "index.html")
         (page-xexp slug tagline (string-append "/blog/" slug "/")
                    nav-xexp
                    (section-xexp slug nodes))))
  ;; (for ([f (in-list (directory-list src-dir))]
  ;;       #:unless (equal? (path->string f) content-file))
  ;;   (copy-directory/files (build-path src-dir f)
  ;;                         (build-path out-dir out-rel f))))

(define (blog-slugs)
  (for/list ([d (in-list (directory-list blog-dir))]
             #:when (directory-exists? (build-path blog-dir d)))
    (path->string d)))

(define (build-blogs)
  (define metas
    (for/list ([slug (in-list (blog-slugs))])
      (define nodes (md->sxml (build-path blog-dir slug content-file)))
      (build-blog slug nodes)
      (define tnode (find-first 'time nodes))
      (define date-text (node-text tnode))
      (define date-sort (or (attr tnode 'datetime) date-text))
      (list slug (node-text (find-first 'h1 nodes)) date-text date-sort)))
  (sort metas string>? #:key (lambda (m) (list-ref m 3))))

(define (new? date-str)
  (define parsed (string->date date-str "~Y-~m-~d"))
  (define now (current-date))
  (define delta (time-difference (date->time-utc now) (date->time-utc parsed)))
  (< (time-second delta) (* 7 24 60 60)))

(define (blog-list metas)
  (for/list ([m (in-list metas)])
    (match-define (list slug title date-text date-sort) m)
    `(p (@ (class "blog-list"))
        ,@(if (new? date-sort)
              '((span (@ (class "new")) "NEW!") " ")
              '())
        (time (@ (datetime ,date-sort)) ,date-text)
        " "
        (a (@ (href ,(string-append "/blog/" slug "/"))) ,title))))

;; Copy Assets
;; (for ([asset assets]
;;       #:when (or (file-exists? asset) (directory-exists? asset)))
;;   (copy-directory/files asset (build-path out-dir asset)))

;; Pages
(define metas (build-blogs))

(build "index.html"
       (page-xexp host tagline "/"
                  header-xexp
                  `(main
                     ,(section-xexp "about" (md->sxml "home/about.md"))
                     ,(section-xexp "blog"
                                    (md->sxml "home/blog.md")
                                    (blog-list metas)
                                    `(p (@ (class "blog-list-end"))))
                     ,(section-xexp "contact" (md->sxml "home/contact.md")))))
