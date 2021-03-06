#lang racket

(require "private/drracket-test-util.rkt")

(fire-up-drracket-and-run-tests
 #:prefs '([plt:framework-pref:framework:autosaving-on? #f])
 (λ ()
   (define drr (wait-for-drracket-frame))
   (set-module-language!)
   (clear-definitions drr)
   (insert-in-definitions
    drr
    (~a "#lang typed/racket\n"
        (~s '(: ! (-> Nonnegative-Integer Nonnegative-Integer)))
        "\n"
        (~s '(define (! x) (if (zero? x) 1 (* x (! (- x 1))))))
        "\n"
        (~s '(! 10))))
   (wait-for-online-compilation-to-finish drr)
   (do-execute drr)
   (collect-garbage) (collect-garbage)
       
   (define times-exceeded-previous-maximum
     (let loop ([i 10]
                [previous-maximum #f])
       (cond
         [(zero? i) 0]
         [else
          (do-execute drr)
          (collect-garbage) (collect-garbage)
          (define this-time (current-memory-use))
          (define exceeded-previous-maximum
            (and previous-maximum
                 (previous-maximum . < . this-time)
                 (- this-time previous-maximum)))
          (printf "went up? ~s ~s\n" this-time exceeded-previous-maximum)
          (+ (if (and exceeded-previous-maximum
                      (exceeded-previous-maximum . > . 10000))
                 1 0)
             (loop (- i 1) (if previous-maximum
                               (max previous-maximum this-time)
                               this-time)))])))
   (when (times-exceeded-previous-maximum . > . 5)
     (eprintf "test failed, exceeded previous maximum by 10,000 ~a times\n" times-exceeded-previous-maximum))))
