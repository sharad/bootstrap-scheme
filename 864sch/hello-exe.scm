(load "asm86.scm")
(define (program)
  (load "pe.scm")
 (: 'start)
  (push -12) ;STDOUT
  (calln (@ 'GetStdHandle))
  (push 0)
  (push 'bytes_written)
  (push 13) ;Number of bytes to write
  (push 'hello)
  (push eax) ;File Handle
  (calln (@ 'WriteFile))
  (ret)
  (data)
 (: 'hello)
  (asciz "Hello World!\n")
  (bss 'bytes_written 0))
(compile program "hello.exe")
