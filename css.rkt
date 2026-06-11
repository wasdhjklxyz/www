#lang racket

(provide css color-bg) ; color-bg feeds the theme-color meta tag

(require css-expr)

(define color-bg         '|#0d0d0d|)
(define color-fg         '|#bebebe|)
(define color-dim        '|#5e5e5e|)
(define color-ldim       '|#7d7d7d|)
(define color-dark       '|#1d1d1d|)
(define color-link       '|#7fb0c0|)
(define color-link-hover '|#8fc0d0|)

(define font               'monospace)
(define font-weight-normal 400)
(define font-weight-bold   600)
(define font-size          '|1rem|)
(define font-size-sm       '|0.8rem|)
(define font-size-md       '|0.85rem|)
(define font-size-lg       '|1.25rem|)
(define font-size-xl       '|1.5rem|)

(define line-height     1.6)
(define line-height-nav 1)
(define line-height-art 0.85)
(define letter-spacing  '|0.05rem|)

(define space-xxs '|0.1rem|) ; separator lines
(define space-xs  '|0.25rem|)
(define space-sm  '|0.5rem|)
(define space-md  '|1rem|)
(define space-lg  '|1.5rem|)
(define space-xl  '|4rem|)
(define space-lg-neg '|-1.2rem|)

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
      [|a:hover| #:color ,color-link-hover #:text-decoration underline]

      [img #:image-rendering auto]

      [nav #:display flex
           #:align-items left
           #:margin-bottom ,space-md
           #:padding-bottom ,space-sm
           #:border-bottom (,border-width solid ,color-dark)]
      [|nav a| #:color ,color-dim
               #:font-size ,font-size
               #:text-decoration none
               #:letter-spacing ,letter-spacing]
      [|nav .art| #:color ,color-fg #:font-size |clamp(1px, 2vw, 1px)| #:margin 0 #:align-self flex-end]

      [|.links| #:align-self flex-end #:margin-left ,space-sm]
      [|.links span| #:font-weight ,font-weight-bold #:margin-bottom ,space-sm]
      [|.links a|
                #:margin-right ,space-sm
                #:font-size ,font-size-md
                #:display flex
                #:text-align left
                #:flex-direction column
                #:line-height ,line-height-nav
                #:font-weight ,font-weight-normal]
      [|.links a:hover| #:color ,color-dim #:text-decoration underline]
      [|.links div| #:display flex #:flex-direction horizontal]

      [|.art| #:display block
              #:width max-content
              #:max-width |100%|
              #:margin (0 auto)
              #:white-space pre
              #:font-size |clamp(1px, 2vw, 4px)|
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

      [h1 #:margin 0
          #:font-size ,font-size-xl
          #:position relative
          #:font-weight ,font-weight-bold]

      [h2 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:position relative
          #:font-weight ,font-weight-bold]
      [|h2::after| #:content "§ "
                   #:color ,color-ldim
                   #:position absolute
                   #:left ,space-lg-neg
                   #:opacity 0]
      [|h2:hover| #:text-decoration underline #:color ,color-ldim]
      [|h2:hover::after| #:opacity 1]

      [h3 #:margin (0 0 ,space-xs)
          #:position relative
#:font-size ,font-size
          #:font-weight ,font-weight-bold]
      [|h3::after| #:content "§ "
                   #:color ,color-ldim
                   #:position absolute
                   #:left ,space-lg-neg
                   #:opacity 0]
      [|h3:hover| #:text-decoration underline #:color ,color-ldim]
      [|h3:hover::after| #:opacity 1]

      [h4 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:position relative
          #:font-weight ,font-weight-bold]
      [|h4::before| #:content "#### " #:color ,color-ldim]
      [|h4::after| #:content "§ "
                   #:color ,color-ldim
                   #:position absolute
                   #:left ,space-lg-neg
                   #:opacity 0]
      [|h4:hover| #:text-decoration underline #:color ,color-ldim]
      [|h4:hover::after| #:opacity 1]

      [h5 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-lg
          #:position relative
          #:font-weight ,font-weight-bold]
      [|h5::before| #:content "##### " #:color ,color-ldim]
      [|h5::after| #:content "§ "
                   #:color ,color-ldim
                   #:position absolute
                   #:left ,space-lg-neg
                   #:opacity 0]
      [|h5:hover| #:text-decoration underline #:color ,color-ldim]
      [|h5:hover::after| #:opacity 1]

      [p  #:margin (0 0 ,space-md)]
      [ul #:margin (0 0 0) #:padding-left ,space-md]

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
      [|footer a:hover| #:color ,color-dim]
      [|footer .sep| #:margin (0 ,space-xxs)])))
