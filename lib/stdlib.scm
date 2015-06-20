(define number? integer?)

(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))
(define (caaar x) (car (car (car x))))
(define (caadr x) (car (car (cdr x))))
(define (cadar x) (car (cdr (car x))))
(define (caddr x) (car (cdr (cdr x))))
(define (cdaar x) (cdr (car (car x))))
(define (cdadr x) (cdr (car (cdr x))))
(define (cddar x) (cdr (cdr (car x))))
(define (cdddr x) (cdr (cdr (cdr x))))
(define (caaaar x) (car (car (car (car x)))))
(define (caaadr x) (car (car (car (cdr x)))))
(define (caadar x) (car (car (cdr (car x)))))
(define (caaddr x) (car (car (cdr (cdr x)))))
(define (cadaar x) (car (cdr (car (car x)))))
(define (cadadr x) (car (cdr (car (cdr x)))))
(define (caddar x) (car (cdr (cdr (car x)))))
(define (cadddr x) (car (cdr (cdr (cdr x)))))
(define (cdaaar x) (cdr (car (car (car x)))))
(define (cdaadr x) (cdr (car (car (cdr x)))))
(define (cdadar x) (cdr (car (cdr (car x)))))
(define (cdaddr x) (cdr (car (cdr (cdr x)))))
(define (cddaar x) (cdr (cdr (car (car x)))))
(define (cddadr x) (cdr (cdr (car (cdr x)))))
(define (cdddar x) (cdr (cdr (cdr (car x)))))
(define (cddddr x) (cdr (cdr (cdr (cdr x)))))

(define (length items)
  (define (iter a count)
    (if (null? a)
        count
        (iter (cdr a) (+ 1 count))))
  (iter items 0))

(define (append list1 list2)
  (if (null? list1)
      list2
      (cons (car list1) (append (cdr list1) list2))))

(define (reverse l)
  (define (iter in out)
    (if (pair? in)
        (iter (cdr in) (cons (car in) out))
        out))
  (iter l '()))

(define (map proc items)
    (if (null? items)
        '()
        (cons (proc (car items))
              (map proc (cdr items)))))

(define (for-each f l)
  (if (null? l)
      #t
      (begin
        (f (car l))
        (for-each f (cdr l)))))

(define (not x)
  (if x #f #t))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (not x)            (if x #f #t))
;; (define (null? obj)        (if (eqv? obj '()) #t #f))


(define (list . objs)       objs)
(define (id obj)           obj)
(define (flip func)        (lambda (arg1 arg2) (func arg2 arg1)))
(define (curry func arg1)  (lambda (arg) (apply func (cons arg1 (list arg)))))
(define (compose f g)      (lambda (arg) (f (apply g arg))))

(define zero?              (curry = 0))
(define positive?          (curry < 0))
(define negative?          (curry > 0))
(define (odd? num)         (= (mod num 2) 1))
(define (even? num)        (= (mod num 2) 0))

(define (foldr func end lst)
  (if (null? lst)
      end
      (func (car lst) (foldr func end (cdr lst)))))

(define (foldl func accum lst)
  (if (null? lst)
      accum
      (foldl func (func accum (car lst)) (cdr lst))))

(define fold foldl)
(define reduce foldr)

(define (unfold func init pred)
  (if (pred init)
      (cons init '())
      (cons init (unfold func (func init) pred))))

(define (sum . lst)         (fold + 0 lst))
(define (product . lst)     (fold * 1 lst))

;; TODO
;; both ae not helpful as it do evaluation of arguments.
;; (define (and . lst)         (fold (lambda (arg1 arg2) (&& arg1 arg2)) #t lst))
;; (define (or . lst)          (fold (lambda (arg1 arg2) (|| arg1 arg2)) #t lst))
;; (define (and . lst)         (fold && #f lst))
;; (define (or . lst)          (fold || #f lst))

(define (max first . rest) (fold (lambda (old new) (if (> old new) old new)) first rest))
(define (min first . rest) (fold (lambda (old new) (if (< old new) old new)) first rest))

(define (length lst)        (fold (lambda (x y) (+ x 1)) 0 lst))

(define (reverse lst)       (fold (flip cons) '() lst))

(define (mem-helper pred op)
  (lambda (acc next)
    (if (and (not acc)
             (pred (op next)))
        next
        acc)))

(define (memq obj lst)       (fold (mem-helper (curry eq? obj) id) #f lst))
(define (memv obj lst)       (fold (mem-helper (curry eqv? obj) id) #f lst))
(define (member obj lst)     (fold (mem-helper (curry equal? obj) id) #f lst))
(define (assq obj alist)     (fold (mem-helper (curry eq? obj) car) #f alist))
(define (assv obj alist)     (fold (mem-helper (curry eqv? obj) car) #f alist))
(define (assoc obj alist)    (fold (mem-helper (curry equal? obj) car) #f alist))

(define (map func lst)      (foldr (lambda (x y) (cons (func x) y)) '() lst))

(define (filter pred lst)   (foldr (lambda (x y) (if (pred x) (cons x y) y)) '() lst))

;; (define (eqv? obj1 obj2)
;;   (if (and
;;        (pair? obj1)
;;        (pair? obj2))
;;       ))

;; 'stdlib-loaded


;;;

;; (define (curry func arg1)  (lambda (arg) (apply func (cons arg1 (list arg)))))
;; (define (not x)            (if x #f #t))
;; (define (curry func arg1)  (lambda (arg) (apply func (cons arg1 (list arg)))))
;; (define (foldl func accum lst)
;;   (if (null? lst)
;;       accum
;;       (foldl func (func accum (car lst)) (cdr lst))))
;; (define fold foldl)
;; (define (mem-helper pred op)
;;   (lambda (acc next)
;;     (if (&& (not acc)
;;              (pred (op next)))
;;         next
;;         acc)))
;; (define (assq obj alist)     (fold (mem-helper (curry eq? obj) car) #f alist))
;; (define (assv obj alist)     (fold (mem-helper (curry eqv? obj) car) #f alist))

;; (assq 'x '((x 1) (y 2)))
;; (assq 'y '((x 1) (y 2)))

;; (define display write)
(define (newline) (display #\newline))

;; ((lambda (arg) (apply eq? (cons 4 (list arg)))) 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define open-output-file  open-output-port)
(define close-output-file close-output-port)
(define open-input-file   open-input-port)
(define close-input-file  close-input-port)


(define (>= arg1 arg2) (|| (= arg1 arg2) (> arg1 arg2)))
(define (<= arg1 arg2) (|| (= arg1 arg2) (< arg1 arg2)))
;; (define (and . lst)         (fold (lambda (arg1 arg2) (&& arg1 arg2)) #t lst))
;; (define (and . lst)         (fold (lambda (arg1 arg2) (&& arg1 arg2)) #t lst))

'stdlib-loaded
