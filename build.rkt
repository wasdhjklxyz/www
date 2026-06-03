#lang racket

(require "css.rkt" "html.rkt")

(display (html-head #:css css
                    #:theme-color color-bg))
