#lang racket

(provide css color-bg) ; color-bg feeds the theme-color meta tag

(require css-expr)

(define color-bg   '|#000000|)
(define color-fg   '|#cecece|)
(define color-dim  '|#454545|)
(define color-dark '|#101010|)
(define color-link '|#ececec|)

(define font               'monospace)
(define font-weight-normal 400)
(define font-weight-bold   600)
(define font-size          '|1rem|)
(define font-size-sm       '|0.8rem|)
(define font-size-md       '|0.85rem|)
(define font-size-lg       '|1.25rem|)
(define font-size-xl       '|1.5rem|)

(define line-height     1.6)
(define line-height-art 0.85)
(define letter-spacing  '|0.05rem|)

(define space-xxs '|0.1rem|) ; separator lines
(define space-xs  '|0.25rem|)
(define space-sm  '|0.5rem|)
(define space-md  '|1rem|)
(define space-lg  '|1.5rem|)
(define space-xl  '|4rem|)

(define max-width     '|44rem|)
(define border-width  '|1px|)
(define button-width  '|88px|)
(define button-height '|31px|)

(define css
  (css-expr->css
    (css-expr
      [* #:box-sizing border-box]

      [body #:margin (0 auto)
            #:padding (,space-lg ,space-md ,space-xl)
            #:background ,color-bg
            #:color ,color-fg
            #:font-family ,font
            #:font-size ,font-size
            #:line-height ,line-height
            #:max-width ,max-width]

      [a #:color ,color-link #:text-decoration underline]
      [|a:hover| #:color ,color-fg #:text-decoration underline]

      [img #:image-rendering auto]

      [nav #:display flex
           #:justify-content space-between
           #:align-items center
           #:margin-bottom ,space-sm
           #:padding-bottom ,space-sm
           #:border-bottom (,border-width solid ,color-dark)]
      [|nav a| #:color ,color-dim
               #:font-size ,font-size
               #:font-weight ,font-weight-bold
               #:text-decoration none
               #:letter-spacing ,letter-spacing]
      [|nav a:hover| #:color ,color-dim #:text-decoration none]

      [|.links a| #:color ,color-dim
                  #:font-size ,font-size
                  #:font-weight ,font-weight-normal]
      [|.links a:hover| #:text-decoration underline]

      [|.art| #:display block
              #:width max-content
              #:max-width |100%|
              #:margin (0 auto)
              #:white-space pre
              #:font-size |clamp(1px, 2vw, 6px)|
              #:line-height ,line-height-art
              #:overflow hidden]

      [big #:text-align center
           #:display block
           #:margin (,space-sm 0 0)
           #:font-size ,font-size-xl
           #:font-weight ,font-weight-bold
           #:letter-spacing ,letter-spacing]

      [small #:margin (,space-xs 0 ,space-xs)
             #:display block
             #:text-align center
             #:font-size ,font-size-md
             #:color ,color-dim]

      [article #:margin (,space-md 0)]

      [h1 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:font-weight ,font-weight-bold]
      [|h1::before| #:content "# "]

      [h2 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:font-weight ,font-weight-bold]
      [|h2::before| #:content "## "]

      [h3 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:font-weight ,font-weight-bold]
      [|h3::before| #:content "### "]

      [h4 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:font-weight ,font-weight-bold]
      [|h4::before| #:content "#### "]

      [h5 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:font-weight ,font-weight-bold]
      [|h5::before| #:content "##### "]

      [p  #:margin (0 0 ,space-md)]
      [ul #:margin (0 0 ,space-md) #:padding-left ,space-md]

      [time #:color ,color-dim #:white-space nowrap]

      [|.buttons| #:display flex
                  #:flex-wrap wrap
                  #:justify-content center
                  #:gap ,space-sm
                  #:margin-top ,space-md
                  #:padding-top ,space-md
                  #:border-top (,border-width solid ,color-dark)]
      [|.buttons + .buttons| #:border-top none
                             #:margin-top ,space-sm
                             #:padding-top ,space-sm]
      [|.buttons img| #:image-rendering pixelated
                      #:display block
                      #:width ,button-width
                      #:height ,button-height
                      #:border 0]
      [|.buttons a| #:line-height 0]

      [footer #:margin-top ,space-md
              #:padding-top ,space-sm
              #:border-top (,border-width solid ,color-dark)
              #:text-align center
              #:font-size ,font-size-sm
              #:color ,color-dim]
      [|footer a| #:color ,color-dim #:text-decoration none]
      [|footer .sep| #:margin (0 ,space-xxs)])))
