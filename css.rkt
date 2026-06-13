#lang racket

(provide css color-bg) ; color-bg feeds the theme-color meta tag

(require css-expr)

(define color-bg         '|#000000|)
(define color-quote      '|#9e9e9e|)
(define color-fg         '|#bebebe|)
(define color-lfg        '|#cecece|)
(define color-dim        '|#5e5e5e|)
(define color-dark       '|#1d1d1d|)
(define color-link       '|#7e8aa1|)
(define color-link-hover '|#8e9ab1|)
(define color-code       '|#7e8aa1|)

;(define font '|ui-monospace, "Cascadia Code", "Source Code Pro", Menlo, Consolas, "DejaVu Sans Mono", monospace|)
(define font "Space Grotesk")
(define font-weight-normal 400)
(define font-weight-bold   600)
(define font-size          '|1.25rem|)
(define font-size-sm       '|0.85rem|)
(define font-size-md       '|1rem|)
(define font-size-lg       '|1.5rem|)
(define font-size-xl       '|1.75rem|)

(define line-height     1.6)
(define line-height-nav 1)
(define line-height-art 0.85)
(define line-height-code 1.25)
(define letter-spacing  '|0.05rem|)

(define space-xxs '|0.1rem|) ; separator lines
(define space-xs  '|0.25rem|)
(define space-sm  '|0.5rem|)
(define space-md  '|1rem|)
(define space-lg  '|1.5rem|)
(define space-xl  '|4rem|)
(define space-neg '|-1.2rem|)

(define max-width     '|64rem|)
(define border-width  '|1px|)
(define border-width-quote '|0.25rem|)
(define button-width  '|88px|)
(define button-height '|31px|)

(define css
  (string-append
  (file->string "pygments.css")
  (css-expr->css
    (css-expr
      [* #:box-sizing border-box]

      [body #:margin (0 auto)
            #:padding (,space-lg 0 ,space-lg)
            #:background ,color-bg
            #:color ,color-fg
            #:font-family ,font
            #:font-size ,font-size
            #:line-height ,line-height
            #:max-width ,max-width]

      [a #:color ,color-link
         #:text-decoration underline]
      [|a:hover| #:color ,color-link-hover
                 #:text-decoration underline]

      [img #:image-rendering auto
           #:max-width ,max-width
           #:margin-bottom ,space-lg]

      [nav #:display flex
           #:margin-bottom ,space-md
           #:padding-bottom ,space-sm
           #:border-bottom (,border-width solid ,color-dark)]
      [|nav a| #:color ,color-dim
               #:text-decoration none
               #:letter-spacing ,letter-spacing]
      [|nav .art| #:color ,color-fg
                  #:font-size |1px|
                  #:margin 0 #:align-self flex-end]

      [|.links| #:align-self flex-end
                #:margin-left ,space-sm]
      [|.links span| #:font-weight ,font-weight-bold 
                     #:margin-bottom ,space-sm]
      [|.links a| #:margin-right ,space-sm
                  #:font-size ,font-size-md
                  #:display flex
                  #:text-align left
                  #:flex-direction column
                  #:line-height ,line-height-nav
                  #:font-weight ,font-weight-normal]
      [|.links a:hover| #:color ,color-dim 
                        #:text-decoration underline]
      [|.links div| #:display flex]

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

      [h1 #:margin 0
          #:font-size ,font-size-xl
          #:font-weight ,font-weight-bold]

      [h2 #:margin (0 0 ,space-xs)
          #:font-size ,font-size-xl
          #:position relative
          #:font-weight ,font-weight-bold]

      [|h3, h4| #:margin (0 0 ,space-xs)
                #:font-size ,font-size-lg
                #:position relative
                #:font-weight ,font-weight-bold]

      [|h2 a, h3 a, h4 a| #:color inherit
                          #:text-decoration none]

      [|h2 a::after, h3 a::after, h4 a::after| #:content "§ "
                                               #:color ,color-lfg
                                               #:position absolute
                                               #:left ,space-neg
                                               #:opacity 0]
      [|h2 a:hover, h3 a:hover, h4 a:hover| #:text-decoration underline
                                            #:color ,color-lfg]
      [|h2 a:hover::after, h3 a:hover::after, h4 a:hover::after| #:opacity 1]

      [p  #:margin (0 0 ,space-lg)]
      [ul #:margin (,space-md ,space-md ,space-lg)
          #:padding-left ,space-md]

      [blockquote #:color ,color-quote
                  #:margin-left ,space-md
                  #:padding (0 ,space-md 0)
                  #:border-left (,border-width-quote solid ,color-dark)]

      [code #:color ,color-code
            #:border (,border-width solid ,color-dark)]

      [|.figure| #:display flex
                 #:justify-content center]

      [|.caption| #:display none]

      [|#blog p| #:margin 0]
      [|#blog .blog-list-end| #:margin (0 0 ,space-md)]

      [|.highlight| #:margin (0 0 ,space-lg)
                    #:background transparent
                    #:border (,border-width solid ,color-dark)]
      [|.highlight pre| #:margin (0 auto 0)
                        #:line-height ,line-height-code
                        #:color ,color-code
                        #:padding ,space-sm]

      [time #:color ,color-dim
            #:white-space nowrap]

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
      [|footer a| #:color ,color-dim
                  #:text-decoration none]
      [|footer a:hover| #:color ,color-dim]
      [|footer .sep| #:margin (0 ,space-xxs)]))))
