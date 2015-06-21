
(define (test1)
 (and #t #t #f (car '()) #f))

(define (test2)
  (define kk 1)
  (define (ww x y . z) (set! kk 2))
  (ww 1 2))


(begin
  (test1)
  (test2))
