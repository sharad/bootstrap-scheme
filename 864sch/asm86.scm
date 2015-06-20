;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; This is an x86 assembler implemented in Scheme.                         ;;;
;;; Not all x86 instructions are yet implemented,                           ;;;
;;; But enough are implemented to compile the Dream Scheme Interpreter. :-) ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;This program is distributed under the terms of the       ;;;
;;;GNU General Public License.                              ;;;
;;;Copyright (C) 2009 David Joseph Stith                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;If using, for instance, guile,
;(define & logand)
;or else define & to be whatever your bitwise-and procedure is
;
(define asm86-text-start #x08048000) ;use #x400000 on Windows
(define asm86-data-start 0)
(define asm86-bss-start 0)
(define asm86-bss-end 0)
(define (display-hex n)
  ;; (if (< n 16) (display "0")) ;; -- sharad have added for padding
  (display (number->string n 16)))
(define (compile thunk object start)
   (if (null? start) (set! start #x08048000)) ;; -- sharad
   (set! asm86-text-start start)
   (set! asm86-out-port #f)
   (asm86-first-pass)
   (thunk)
   (asm86-insure-bss)
   (set! asm86-bss-end asm86-address)
   (set! asm86-out-port (open-output-file object))
   (asm86-second-pass)
   (display "text-start=")(display-hex asm86-text-start)(newline)
   (display "data-start=")(display-hex asm86-data-start)(newline)
   (display "bss-start=")(display-hex asm86-bss-start)(newline)
   (display "bss-end=")(display-hex asm86-bss-end)(newline)
   (thunk)
   (close-output-port asm86-out-port))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define asm86-out-port #f)
;;;;;;;;;;;;;;;;;;;;;;;;
;;;Assembly Registers;;;
;;;;;;;;;;;;;;;;;;;;;;;;
(define r0 (lambda () 0))
(define r1 (lambda () 1))
(define r2 (lambda () 2))
(define r3 (lambda () 3))
(define r4 (lambda () 4))
(define r5 (lambda () 5))
(define r6 (lambda () 6))
(define r7 (lambda () 7))
(define cr0 (lambda () 0))
(define cr1 (lambda () 1))
(define es (lambda () 0))
(define cs (lambda () 1))
(define ss (lambda () 2))
(define ds (lambda () 3))
(define fs (lambda () 4))
(define gs (lambda () 5))
(define eax r0)
(define ax r0)
(define al r0)
(define ecx r1)
(define cx r1)
(define cl r1)
(define edx r2)
(define dx r2)
(define dl r2)
(define ebx r3)
(define bx r3)
(define bl r3)
(define esp r4)
(define sp r4)
(define ah r4)
(define ebp r5)
(define bp r5)
(define ch r5)
(define esi r6)
(define si r6)
(define dh r6)
(define edi r7)
(define di r7)
(define bh r7)

;;;;;;;;;;;;;;;;;;;;;;
;;;One-byte Opcodes;;;
;;;;;;;;;;;;;;;;;;;;;;
(define (opd-size)
  (asm86-byte #x66)
  (set! asm86-opd-size? #t))
(define (addr-size)
  (asm86-byte #x67)
  (set! asm86-addr-size? #t))

(define (pusha) (op #x60))
(define (popa) (op #x61))
(define (pushf) (op #x9c))
(define (popf) (op #x9d))
(define (nop) (op #x90))
(define (movsb) (op #xa4))
(define (movs) (op #xa5))
(define (cmpsb) (op #xa6))
(define (cmps) (op #xa7))
(define (stosb) (op #xaa))
(define (stos) (op #xab))
(define (lodsb) (op #xac))
(define (lods) (op #xad))
(define (cdq) (op #x99))
(define (ret) (op #xc3))
(define (iret) (op #xcf))
(define (repne) (op #xf2))
(define (rep) (op #xf3))
(define repe rep)
(define (clc) (op #xf8))
(define (stc) (op #xf9))
(define (cli) (op #xfa))
(define (sti) (op #xfb))
(define (cld) (op #xfc))
(define (std) (op #xfd))

(define (inb x)
  (cond
    ((eq? x dx)
     (op #xec))
    (else
     (op #xe4)
     (asm86-byte x))))
(define (in x)
  (cond
    ((eq? x dx)
     (op #xed))
    (else
     (op #xe5)
     (asm86-byte x))))
(define (outb x)
  (cond
    ((eq? x dx)
     (op #xee))
    (else
     (op #xe6)
     (asm86-byte x))))
(define (out x)
  (cond
    ((eq? x dx)
     (op #xef))
    (else
     (op #xe7)
     (asm86-byte x))))

(define (int n) (op #xcd) (asm86-byte n))

(define (seg= x)
  (cond
    ((eq? x fs) (op #x64))
    ((eq? x gs) (op #x65))
    ((asm86-segment-register? x) (op (+ #x26 (* 8 (x)))))
    (else (asm86-error 'segment-reg))))
(define (pop x)
  (cond
    ((asm86-segment-register? x)
     (cond
       ((eq? x cs)
        (asm86-error 'pop-cs))
       ((eq? x fs) (op2 #xa1))
       ((eq? x gs) (op2 #xa9))
       (else (op (+ #x07 (* 8 (x)))))))
    ((asm86-register? x)
     (op (+ #x58 (x))))
    ((pair? x)
     (op #x8f)
     (apply asm86-r/m (cons r0 x)))
    (else
      (asm86-error 'pop-constant))))
(define (xchg r)
  (asm86-assert-reg r)
  (op (+ #x90 (r))))

(define (pushb x)
  (op #x6a)
  (asm86-byte x))

(define (lea a b)
  (if (pair? a)
    (begin (op #x8d) (apply asm86-r/m (cons b a)))
    (asm86-error 'lea-first-arg)))

;;;;;;;;;;;;;
;;;Group 1;;;
;;;;;;;;;;;;;
(define (addb a b) (asm86-group1b a b #x00 r0))
(define (add a b) (asm86-group1tb a b #x01 r0))

(define (orb a b) (asm86-group1b a b #x08 r1))
(define (or! a b) (asm86-group1tb a b #x09 r1))

(define (adcb a b) (asm86-group1b a b #x10 r2))
(define (adc a b) (asm86-group1tb a b #x11 r2))

(define (sbbb a b) (asm86-group1b a b #x18 r3))
(define (sbb a b) (asm86-group1tb a b #x19 r3))

(define (andb a b) (asm86-group1b a b #x20 r4))
(define (and! a b) (asm86-group1t a b #x21 r4))

(define (subb a b) (asm86-group1b a b #x28 r5))
(define (sub a b) (asm86-group1tb a b #x29 r5))

(define (xorb a b) (asm86-group1b a b #x30 r6))
(define (xor a b) (asm86-group1tb a b #x31 r6))

(define (cmpb a b) (asm86-group1b a b #x38 r7))
(define (cmp a b) (asm86-group1tb a b #x39 r7))

;;;;;;;;;;;;;
;;;Group 2;;;
;;;;;;;;;;;;;
(define (rolb a b) (asm86-group2 a b r0 0))
(define (rol a b) (asm86-group2 a b r0 1))
(define (rorb a b) (asm86-group2 a b r1 0))
(define (ror a b) (asm86-group2 a b r1 1))
(define (rclb a b) (asm86-group2 a b r2 0))
(define (rcl a b) (asm86-group2 a b r2 1))
(define (rcrb a b) (asm86-group2 a b r3 0))
(define (rcr a b) (asm86-group2 a b r3 1))
(define (shlb a b) (asm86-group2 a b r4 0))
(define salb shlb)
(define (shl a b) (asm86-group2 a b r4 1))
(define sal shl)
(define (shrb a b) (asm86-group2 a b r5 0))
(define (shr a b) (asm86-group2 a b r5 1))
(define (sarb a b) (asm86-group2 a b r7 0))
(define (sar a b) (asm86-group2 a b r7 1))

;;;;;;;;;;;;;
;;;Group 3;;;
;;;;;;;;;;;;;
(define (test a b)
  (asm86-op-r/m a b #x85 #x85
    (lambda ()
      (op #xf7)
      (asm86-r/m-eg r0 b)
      (word a))))

(define (testb a b)
  (asm86-op-r/m a b #x84 #x84
    (lambda ()
      (op #xf6)
      (asm86-r/m-eg r0 b)
      (asm86-byte a))))

(define (notb x) (op #xf6) (asm86-r/m-eg r2 x))
(define (not! x) (op #xf7) (asm86-r/m-eg r2 x))
(define (negb x) (op #xf6) (asm86-r/m-eg r3 x))
(define (neg x) (op #xf7) (asm86-r/m-eg r3 x))
(define (mulb x) (op #xf6) (asm86-r/m-eg r4 x))
(define (mul x) (op #xf7) (asm86-r/m-eg r4 x))
(define (imulb x) (op #xf6) (asm86-r/m-eg r5 x))
(define (imul x) (op #xf7) (asm86-r/m-eg r5 x))
(define (divb x) (op #xf6) (asm86-r/m-eg r6 x))
(define (div x) (op #xf7) (asm86-r/m-eg r6 x))
(define (idivb x) (op #xf6) (asm86-r/m-eg r7 x))
(define (idiv x) (op #xf7) (asm86-r/m-eg r7 x))

;;;;;;;;;;;;;
;;;Group 4;;;
;;;;;;;;;;;;;
(define (incb x) (op #xfe) (asm86-r/m-eg r0 x))
(define (decb x) (op #xfe) (asm86-r/m-eg r1 x))

;;;;;;;;;;;;;
;;;Group 5;;;
;;;;;;;;;;;;;
(define (inc x)
  (cond
    ((asm86-register? x)
     (op (+ #x40 (x))))
    ((pair? x)
     (op #xff)
     (apply asm86-r/m (cons r0 x)))
    (else
      (asm86-error 'inc-constant))))
(define (dec x)
  (cond
    ((asm86-register? x)
     (op (+ #x48 (x))))
    ((pair? x)
     (op #xff)
     (apply asm86-r/m (cons r1 x)))
    (else
      (asm86-error 'dec-constant))))
(define (calln x)
  (if (pair? x)
    (begin
      (op #xff)
      (apply asm86-r/m (cons r2 x)))
    (asm86-error 'calln-arg)))
(define (callf x)
  (if (pair? x)
    (begin
      (op #xff)
      (apply asm86-r/m (cons r3 x)))
    (asm86-error 'callf-arg)))
(define (jmpn x)
  (if (pair? x)
    (begin
      (op #xff)
      (apply asm86-r/m (cons r4 x)))
    (asm86-error 'jmpn-arg)))
(define (jmpf x)
  (if (pair? x)
    (begin
      (op #xff)
      (apply asm86-r/m (cons r5 x)))
    (asm86-error 'jmpf-arg)))
(define (push x)
  (cond
    ((asm86-segment-register? x)
     (cond
       ((eq? x fs) (op2 #xa0))
       ((eq? x gs) (op2 #xa8))
       (else (op (+ #x06 (* 8 (x)))))))
    ((asm86-register? x)
     (op (+ #x50 (x))))
    ((pair? x)
     (op #xff)
     (apply asm86-r/m (cons r6 x)))
    (else
      (op #x68)
      (word x))))

;;;;;;;;;;;;;;
;;;Group 11;;;
;;;;;;;;;;;;;;
(define (mov a b)
  (cond
    ((and (eq? a r0) (asm86-direct-address? b))
     (op #xa3)
     (word-address (car b)))
    ((and (eq? b r0) (asm86-direct-address? a))
     (op #xa1)
     (word-address (car a)))
    ((asm86-segment-register? a)
     (op #x8c)
     (asm86-r/m-eg a b))
    ((asm86-segment-register? b)
     (op #x8e)
     (asm86-r/m-eg b a))
    ((asm86-control-register? a)
     (op2 #x20)
     (asm86-mod-r/m 3 a b))
    ((asm86-control-register? b)
     (op2 #x22)
     (asm86-mod-r/m 3 b a))
    (else
      (asm86-op-r/m a b #x89 #x8b
        (lambda ()
          (cond
            ((asm86-register? b)
             (op (+ #xb8 (b)))
             (word a))
            ((pair? b)
             (op #xc7)
             (apply asm86-r/m (cons r0 b))
             (word a))
            (else (asm86-error 'mov-args))))))))

(define (movb a b)
  (asm86-op-r/m a b #x88 #x8a
    (lambda ()
      (cond
        ((asm86-register? b)
         (op (+ #xb0 (b)))
         (asm86-byte a))
        ((pair? b)
         (op #xc6)
         (apply asm86-r/m (cons r0 b))
         (asm86-byte a))
        (else (asm86-error 'movb-args))))))

;;;;;;;;;;;
;;;Jumps;;;
;;;;;;;;;;;
(define (jo d) (op #x70) (rel-byte d))
(define (jno d) (op #x71) (rel-byte d))
(define (jb d) (op #x72) (rel-byte d))
(define jnae jb)
(define jc jb)
(define (jnb d) (op #x73) (rel-byte d))
(define jae jnb)
(define jnc jnb)
(define (jz d) (op #x74) (rel-byte d))
(define je jz)
(define (jnz d) (op #x75) (rel-byte d))
(define jne jnz)
(define (jbe d) (op #x76) (rel-byte d))
(define jna jbe)
(define (jnbe d) (op #x77) (rel-byte d))
(define ja jnbe)
(define (js d) (op #x78) (rel-byte d))
(define (jns d) (op #x79) (rel-byte d))
(define (jp d) (op #x7a) (rel-byte d))
(define jpe jp)
(define (jnp d) (op #x7b) (rel-byte d))
(define jpo jnp)
(define (jl d) (op #x7c) (rel-byte d))
(define jnge jl)
(define (jnl d) (op #x7d) (rel-byte d))
(define jge jnl)
(define (jle d) (op #x7e) (rel-byte d))
(define jng jle)
(define (jnle d) (op #x7f) (rel-byte d))
(define jg jnle)

(define (jcxz d) (op #xe3) (rel-byte d))
(define jecxz jcxz)

(define (loopne d) (op #xe0) (rel-byte d))
(define loopnz loopne)

(define (loope d) (op #xe1) (rel-byte d))
(define loopz loope)

(define (loop d) (op #xe2) (rel-byte d))

(define (call a) (op #xe8) (rel-word a))
(define (jmp d) (op #xeb) (rel-byte d))
(define (far-jmp s a)
  (op #xea)
  (word a)
  (asm86-wyde s))
(define (jmpl d) (op #xe9) (rel-word d))

;;;;;;;;;;;;;;;;;;;;;;
;;;Two-byte Opcodes;;;
;;;;;;;;;;;;;;;;;;;;;;
(define (movzb a b)
  (if (asm86-register? b)
    (begin
      (op2 #xb6)
      (asm86-r/m-eg b a))
    (asm86-error 'movzb-destination)))

(define (jol d) (op2 #x80) (rel-word d))
(define (jnol d) (op2 #x81) (rel-word d))
(define (jbl d) (op2 #x82) (rel-word d))
(define jnael jbl)
(define jcl jbl)
(define (jnbl d) (op2 #x83) (rel-word d))
(define jael jnbl)
(define jncl jnbl)
(define (jzl d) (op2 #x84) (rel-word d))
(define jel jzl)
(define (jnzl d) (op2 #x85) (rel-word d))
(define jnel jnzl)
(define (jbel d) (op2 #x86) (rel-word d))
(define jnal jbel)
(define (jnbel d) (op2 #x87) (rel-word d))
(define jal jnbel)
(define (jsl d) (op2 #x88) (rel-word d))
(define (jnsl d) (op2 #x89) (rel-word d))
(define (jpl d) (op2 #x8a) (rel-word d))
(define jpel jpl)
(define (jnpl d) (op2 #x8b) (rel-word d))
(define jpol jnpl)
(define (jll d) (op2 #x8c) (rel-word d))
(define jngel jll)
(define (jnll d) (op2 #x8d) (rel-word d))
(define jgel jnll)
(define (jlel d) (op2 #x8e) (rel-word d))
(define jngl jlel)
(define (jnlel d) (op2 #x8f) (rel-word d))
(define jgl jnlel)

(define (rdtsc) (op2 #x31))

;;;;;;;;;;;;;
;;;Group 7;;;
;;;;;;;;;;;;;
(define (lgdt a)
  (op2 #x01)
  (asm86-mod-r/m 0 r2 r6)
  (word a))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Pseudo Instructions;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
(define (protected-mode)
  (set! asm86-protected-mode #t))
(define (real-mode)
  (set! asm86-protected-mode #f))
(define (ascii s) s)
(define (data)
  (set! asm86-data-start asm86-address))
(define (bss s n)
  (asm86-insure-bss)
  (: s)
  (asm86-bss n))
(define (lookup s)
  (let ((n (assq s asm86-symbols)))
    (if n (cdr n) (asm86-default-address s))))
(define (file-offset s)
  (if (number? s)
    (- s asm86-text-start)
    (- (lookup s) asm86-text-start)))
(define (: s)
  (let ((n (assq s asm86-symbols)))
    (if n
      (cond ((not (= (cdr n) asm86-address))
             (write s)
             (asm86-error 'label-multiple)))
      (set! asm86-symbols (cons (cons s asm86-address) asm86-symbols)))))
(define (symbol-seq)
  (set! asm86-sequence (+ asm86-sequence 1))
  (string->symbol (number->string asm86-sequence)))
(define (byte n)
  (asm86-byte n))
(define (bytes . x)
  (if (pair? x)
    (begin
      (asm86-byte (car x))
      (apply bytes (cdr x)))))
(define (wyde n)
  (asm86-wyde n))
(define (wydes . x)
  (if (pair? x)
    (begin
      (asm86-wyde (car x))
      (apply wydes (cdr x)))))
(define (word n)
  (if (asm86-opd-16)
    (asm86-wyde n)
    (asm86-tetra n)))
(define (word-address n)
  (if (asm86-addr-16)
    (asm86-wyde n)
    (asm86-tetra n)))
(define (tetra n)
  (asm86-tetra n))
(define (tetras . x)
  (if (pair? x)
    (begin
      (asm86-tetra (car x))
      (apply tetras (cdr x)))))
(define (align n)
  (if (positive? (remainder asm86-address n))
    (begin
      (if asm86-bss?
        (asm86-bss 1)
        (asm86-byte 0))
      (align n))))
(define (asciis . x)
  (if (pair? x)
    (begin
      (ascii (car x))
      (apply asciis (cdr x)))))
(define (asciz s)
  (ascii s)
  (asm86-byte 0))

(define (@ d . x)
  (if (asm86-register? d)
    (begin
      (set! x (cons d x))
      (set! d 0)))
  (if (pair? x)
    (if (pair? (cdr x))
      (list d (car x)
              (cadr x)
              (if (pair? (cddr x))
                (caddr x)
                0))
      (list d (car x) #f 0))
    (list d #f #f 0)))


;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Compiler Internals ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;
;;;Messages;;;
;;;;;;;;;;;;;;
(define (asm86-message msg)
  (display
    (cdr
      (assq msg asm86-messages)))
  (newline))
(define (asm86-error msg)
  (asm86-message msg)
  (exit))
(define asm86-messages
  '((first-pass . "\n-------First Pass-------")
    (second-pass . "\n-------Second Pass-------")
    (bss-bytes . "No bytes can be written in the 'bss' section.")
    (label-undefined . ": Label is not defined.")
    (label-multiple . ": Label exists for multiple distinct addresses.")
    (byte-overflow . "Number is too wide for one byte.")
    (wyde-overflow . "Number is too wide for a 16-bit word.")
    (invalid-register . ": Invalid register")
    (invalid-r/m-prefix . "Invalid mod-r/m prefix.")
    (ebp-with-index . "Cannot use ebp for address when using an index register.")
    (reg-with-word-displacement . "Cannot use register for address with word displacement.")
    (real-shift-index . "Cannot shift index in real mode.")
    (real-mem-with-index . "Only BX and BP may be used as memory pointers with an index in real mode.")
    (real-index . "Only SI and DI may be used as index registers in real mode.")
    (real-mem . "Only SI, DI, BP, or BX may be used as memory pointers in real mode.")
    (second-operand . "Expected register or address as second operand.")
    (segment-reg . "Expected segment register for (seg= x).")
    (pop-cs . "Cannot pop CS register.")
    (pop-constant . "Popping into a constant?  Surely not.")
    (lea-first-arg . "Expected address as first argument to (lea a b)")
    (shift-reg . "Among registers, only CL may be used as a shift index.")
    (shift-constant . "Among integers, only an unsigned byte may be used as a shift index.")
    (shift . "Only byte integers or register cl may be used as a shift index.")
    (inc-constant . "Incrementing a constant?  Surely not.")
    (dec-constant . "Decrementing a constant?  Surely not.")
    (calln-arg . "Expected address as argument to (calln x)")
    (callf-arg . "Expected address as argument to (callf x)")
    (jmpn-arg . "Expected address as argument to (jmpn x)")
    (jmpf-arg . "Expected address as argument to (jmpf x)")
    (mov-args . "Invalid arguments for (mov a b)")
    (movb-args . "Invalid arguments for (movb a b)")
    (byte-branch . ": Branch is too far for one byte branch.")
    (movzb-destination . "The movzb instruction must have a register as its destination.")))

;;;;;;;;;;;;;;;;
;;;Validation;;;
;;;;;;;;;;;;;;;;
(define (asm86-bss-error n)
  (asm86-error 'bss-bytes))
(define (asm86-large? n)
  (if (positive? n)
    (> n #xff)
    (< n #x-80)))
(define (asm86-large-unsigned? n)
  (or (negative? n) (> n #xff)))
(define (asm86-large-signed? n)
  (if (positive? n)
    (> n #x7f)
    (< n #x-80)))
(define (asm86-too-wyde? n)
  (if (positive? n)
    (> n #xffff)
    (< n #x-8000)))

;;;;;;;;;;;;;;;;;
;;;Compilation;;;
;;;;;;;;;;;;;;;;;
(define asm86-address asm86-text-start)
(define asm86-bss? #f)
(define asm86-sequence 0)
(define asm86-symbols '())
(define (asm86-default-address x) asm86-address)
(define (asm86-write-byte n)
  (if (char? n) (set! n (char->integer n)))
  (if (negative? n) (set! n (+ #x100 n)))
  (display "#x")
  ;; (if (< n 16) (display "0")) ;; -- sharad have added for padding
  (display (number->string n 16))
  (newline))
(define (asm86-rewind)
  (set! asm86-address asm86-text-start)
  (set! asm86-bss? #f)
  (set! asm86-sequence 0))
(define (asm86-inc-addr)
  (set! asm86-address (+ 1 asm86-address)))
(define asm86-protected-mode #t)
(define (asm86-insure-bss)
  (if (not asm86-bss?)
    (begin
      (if (zero? asm86-data-start)
        (data))
      (set! asm86-bss-start asm86-address)
      (set! asm86-bss? #t)
      (set! asm86-write-byte asm86-bss-error)
      (set! ascii asm86-bss-error))))
(define (asm86-bss n)
  (set! asm86-address (+ n asm86-address)))
(define (asm86-first-pass . x)
  (asm86-message 'first-pass)
  (asm86-rewind)
  (set! asm86-symbols '())
  (set! asm86-write-byte (lambda (n) #t))
  (set! ascii
    (lambda (s)
      (set! asm86-address (+ asm86-address (string-length s)))))
  (set! asm86-default-address
    (lambda (x) asm86-address)))
(define (asm86-second-pass)
  (asm86-message 'second-pass)
  (asm86-rewind)
  (set! asm86-write-byte
    (lambda (n)
      (write-char
        (if (char? n) n (integer->char (modulo n #x100)))
        asm86-out-port)))
  (set! ascii
    (lambda (s)
      (display s asm86-out-port)
      (set! asm86-address (+ asm86-address (string-length s)))))
  (set! asm86-default-address
    (lambda (x)
      (write x)
      (asm86-error 'label-undefined))))

(define asm86-opd-size? #f)
(define asm86-addr-size? #f)
(define asm86-opd-size-reset? #f)
(define asm86-addr-size-reset? #f)
(define (asm86-byte n)
  (if (and (number? n) (asm86-large? n))
    (asm86-error 'byte-overflow))
  (asm86-write-byte n)
  (asm86-inc-addr))
(define (asm86-wyde n)
  (cond
    ((symbol? n)
     (set! n (lookup n)))
    ((char? n)
     (set! n (char->integer n)))
    ((negative? n)
     (set! n (+ n #x10000))))
  (asm86-byte (& n #xff))
  (asm86-byte (quotient (& n #xff00) #x100))
  (if (asm86-too-wyde? n)
    (asm86-error 'wyde-overflow)))
(define (asm86-opd-16)
  (eq? asm86-protected-mode asm86-opd-size?))
(define (asm86-addr-16)
  (eq? asm86-protected-mode asm86-addr-size?))
(define (asm86-tetra n)
  (cond
    ((number? n) '())
    ((symbol? n)
     (set! n (lookup n)))
    ((char? n)
     (set! n (char->integer n)))
    ((negative? n)
     (set! n (+ n #xffffffff 1)))
    (else (error "n is not number.")))
  (asm86-byte (& n #xff))
  (asm86-byte (quotient (& n #xff00) #x100))
  (asm86-byte (quotient (& n #xff0000) #x10000))
  (asm86-byte (quotient (& n #xff000000) #x1000000)))

(define asm86-register? procedure?)
(define (asm86-segment-register? x)
  (memq x (list es cs ss ds fs gs)))
(define (asm86-control-register? x)
  (memq x (list cr0 cr1)))
(define (asm86-assert-reg r)
  (cond
    ((not (asm86-register? r))
     (write r)
     (asm86-error 'invalid-register))))
(define (op n)
  (asm86-byte n)
  (if asm86-addr-size?
    (if asm86-addr-size-reset?
      (begin
        (set! asm86-addr-size-reset? #f)
        (set! asm86-addr-size? #f))
      (set! asm86-addr-size-reset? #t)))
  (if asm86-opd-size?
    (if asm86-opd-size-reset?
      (begin
        (set! asm86-opd-size-reset? #f)
        (set! asm86-opd-size? #f))
      (set! asm86-opd-size-reset? #t))))
(define (op2 n)
  (op #x0f)
  (asm86-byte n))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Mod-R/M byte encodings;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (asm86-mod-r/m p r m)
  (if (not m) (set! m r4))
  (asm86-assert-reg r)
  (asm86-assert-reg m)
  (if (and (>= p 0) (<= p 3))
    (asm86-byte
      (+ (* p 64)
         (* (r) 8)
         (m)))
    (asm86-error 'invalid-r/m-prefix)))
(define (asm86-r/m2 i m d s)
  (if (and m (eq? m r5))
    (asm86-error 'ebp-with-index)
    (if (zero? d)
      (asm86-mod-r/m s i m)
      (if m
        (asm86-error 'reg-with-word-displacement)
        (begin
          (asm86-mod-r/m s i r5)
          (word-address d))))))
(define (asm86-r/m r d m i s)
  (if (symbol? d) (set! d (lookup d)))
  (if asm86-protected-mode
    (asm86-r/m-32 r d m i s)
    (if (positive? s)
      (asm86-error 'real-shift-index)
      (asm86-r/m-16 r d m i))))
(define (asm86-mod-r/m-16 r d m)
  (cond
    ((zero? d)
     (if (eq? m r6)
       (begin
         (asm86-r/m 1 r m)
         (asm86-byte 0))
       (asm86-mod-r/m 0 r m)))
    ((asm86-large? d)
     (asm86-mod-r/m 2 r m)
     (asm86-wyde d))
    (else
     (asm86-mod-r/m 1 r m)
     (asm86-byte d))))
(define (asm86-r/m-16 r d m i)
  (if i
    (cond
      ((eq? i r6)
       (cond
         ((eq? m r3)
          (asm86-mod-r/m-16 r d r0))
         ((eq? m r5)
          (asm86-mod-r/m-16 r d r2))
         (else (asm86-error 'real-mem-with-index))))
      ((eq? i r7)
       (cond
         ((eq? m r3)
          (asm86-mod-r/m-16 r d r1))
         ((eq? m r5)
          (asm86-mod-r/m-16 r d r3))
         (else (asm86-error 'real-mem-with-index))))
      (else (asm86-error 'real-index)))
    (if m
      (cond
        ((eq? m r6)
         (asm86-mod-r/m-16 r d r4))
        ((eq? m r7)
         (asm86-mod-r/m-16 r d r5))
        ((eq? m r5)
         (asm86-mod-r/m-16 r d r6))
        ((eq? m r3)
         (asm86-mod-r/m-16 r d r7))
        (else (asm86-error 'real-mem)))
      (begin
        (asm86-mod-r/m 0 r r6)
        (word d)))))
(define (asm86-r/m-32 r d m i s)
  (if i
    (if (or (zero? d) (asm86-large? d))
      (begin
        (asm86-mod-r/m 0 r #f)
        (asm86-r/m2 i m d s))
      (begin
        (asm86-mod-r/m 1 r #f)
        (asm86-r/m2 i m 0 s)
        (asm86-byte d)))
    (if m
      (if (or (asm86-large? d) (eq? m r4))
        (asm86-r/m r d #f m 0)
        (if (and (zero? d)
                 (not (eq? m r5)))
          (asm86-mod-r/m 0 r m)
          (begin
            (asm86-mod-r/m 1 r m)
            (asm86-byte d))))
      (begin
        (asm86-mod-r/m 0 r r5)
        (word-address d)))))
(define (asm86-r/m-eg a b)
  (cond
    ((asm86-register? b)
     (asm86-mod-r/m 3 a b))
    ((pair? b)
      (apply asm86-r/m (cons a b)))
    (else (asm86-error 'second-operand))))
(define (asm86-op-r/m a b EG GE immed)
  (cond
    ((asm86-register? a)
     (op EG)
     (asm86-r/m-eg a b))
    ((pair? a)
     (op GE)
     (apply asm86-r/m (cons b a)))
    (else (immed))))
(define (asm86-group1 a b EG ext bop top)
  (asm86-op-r/m a b EG (+ EG 2)
    (lambda ()
      (if (symbol? a) (set! a (lookup a)))
      (if (eq? b r0)
        (begin
          (op (+ EG 4))
          (if top (word a) (asm86-byte a)))
        (begin
          (if (char? a)
            (set! a (char->integer a)))
          (if (or (not bop) (asm86-large? a))
            (if top
              (begin
                (op top)
                (asm86-r/m-eg ext b)
                (word a))
              (asm86-error 'byte-overflow))
            (begin
              (op bop)
              (asm86-r/m-eg ext b)
              (asm86-byte a))))))))

(define (asm86-group1b a b EG ext) (asm86-group1 a b EG ext #x80 #f))
(define (asm86-group1tb a b EG ext) (asm86-group1 a b EG ext #x83 #x81))
(define (asm86-group1t a b EG ext) (asm86-group1 a b EG ext #f #x81))

(define (asm86-group2 a b ext size) ;size: 0=byte, 1=word
  (cond
    ((asm86-register? a)
     (if (eq? a cl)
       (begin
         (op (+ #xd2 size))
         (asm86-r/m-eg ext b))
       (asm86-error 'shift-reg)))
    ((integer? a)
     (if (asm86-large-unsigned? a)
       (asm86-error 'shift-constant)
       (if (= 1 a)
         (begin
           (op (+ #xd0 size))
           (asm86-r/m-eg ext b))
         (begin
           (op (+ #xc0 size))
           (asm86-r/m-eg ext b)
           (asm86-byte a)))))
    (else (asm86-error 'shift))))

(define (asm86-direct-address? x)
  (and (pair? x)
       (not (cadr x))
       (not (caddr x))
       (zero? (cadddr x))))

(define (rel-byte dest)
  (let* ((da (if (symbol? dest) (lookup dest) dest))
         (vec (- da asm86-address 1)))
    (if (asm86-large-signed? vec)
      (begin
        (if (symbol? dest)
          (write dest))
        (asm86-error 'byte-branch)))
    (asm86-byte vec)))
(define (rel-word dest)
  (if (symbol? dest)
    (set! dest (lookup dest)))
  (word (- dest asm86-address (if (asm86-opd-16) 2 4))))
