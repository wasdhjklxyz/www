(require html-template css-expr)

(define *host* "wasdhjkl.xyz")
(define *tagline* "kernels / networking / offensive security / nix btw / nvim btw")
(define *color-bg* '|#000000|)

(define html-style (css-expr
                     [body #:background ,*color-bg*]
                     [h1 #:color |#ff0000|]))

(define html-head (html-template
                    (head
                      (meta (@ (charset "utf-8")))
                      (meta (@ (name "viewport")
                               (content "width=device-width, initial-scale=1")))
                      (meta (@ (name "description")
                               (content (% *tagline*))))
                      (meta (@ (name "theme-color")
                               (content (% (symbol->string *color-bg*)))))
                      (link (@ (rel "canonical")
                               (href (% (string-append "https://" *host*)))))
                      (style (% (css-expr->css html-style)))
                      (title (% *host*)))))

(display html-head)
