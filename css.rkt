#lang racket

(provide css color-bg) ; color-bg feeds the theme-color meta tag

(require css-expr)

(define color-bg   '|#000000|)
(define color-fg   '|#cecece|)
(define color-dim  '|#454545|)
(define color-dark '|#101010|)

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
(define letter-spacing  '|0.5rem|)

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

      [a #:color ,color-fg #:text-decoration none]
      [|a:hover| #:text-decoration underline]

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
               #:letter-spacing ,letter-spacing]

      [|.links a| #:color ,color-dim
                  #:font-size ,font-size
                  #:font-weight ,font-weight-normal]

      [header #:border-bottom (,border-width solid ,color-dark)
              #:margin-bottom ,space-md]

      [|.art| #:display block
              #:width max-content
              #:max-width |100%|
              #:margin (0 auto ,space-sm)
              #:white-space pre
              #:font-size (clamp |1px| |2vw| |6px|) ; TODO
              #:line-height ,line-height-art
              #:overflow hidden]

      [h1 #:text-align center
          #:font-size ,font-size-xl
          #:font-weight ,font-weight-bold
          #:letter-spacing ,letter-spacing]

      [small #:margin (,space-xs 0 ,space-xs)
             #:text-align center
             #:font-size ,font-size-md
             #:color ,color-dim]

      [section #:margin (,space-md 0)]

      [h2 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:font-weight ,font-weight-bold]
      [|h2::before| #:content "# "]

      [p  #:margin (0 0 ,space-md)]
      [ul #:margin (0 0 ,space-md) #:padding-left ,space-md]

      [|.posts| #:list-style none #:padding 0]
      [|.posts li| #:display flex #:gap ,space-md #:padding (,space-xs 0)]
      [|.posts time| #:color ,color-dim #:white-space nowrap]

      [|.projects| #:list-style none #:padding 0]
      [|.projects li| #:display flex
                      #:gap ,space-md
                      #:padding (,space-xs 0)]
      [|.projects span| #:color ,color-dim]

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
      [|footer a| #:color ,color-dim]
      [|footer .sep| #:margin (0 ,space-xxs)])))
