;;;;;;;;;;;;;;;;;;
;;; ELF Header ;;;
;;;;;;;;;;;;;;;;;;

;;;ELF identification
(bytes
  #x7f #\E #\L #\F
  1  ;32bit
  1  ;Little endian
  1  ;File version
  0  ;System V ABI
  0  ;ABI version
  0 0 0 0 0 0 0)
;;;Object File Type
(wyde 2) ;Executable
;;;Architecture
(wyde 3) ;Intel 386
;;;ELF version
(tetra 1) ;Current
;;;Entry point
(tetra 'start)
;;;Program header file offset
(tetra #x34)
;;;Section table file offset
(tetra (file-offset 'section_table_start))
;;;Processor-specific flags
(tetra 0)
;;;ELF header size
(wyde #x34)
;;;Program header table entry size
(wyde #x20)
;;;Program header table entry count
(wyde 2)
;;;Section header table entry size
(wyde #x28)
;;;Section header table entry count
(wyde 0)
;;;Section header string table index
(wyde 0)
;;;
;;;Program header table
;;;
;;;TEXT entry
;;;Segment type
(tetra 1) ;Loadable
;;;Segment file offset
(tetra 0)
;;;Segment virtual address
(tetra asm86-text-start)
;;;Segment physical address
(tetra 0) ;ignored
(let ((size (- asm86-data-start
               asm86-text-start)))
  ;;;Segment file size
  (tetra size)
  ;;;Segment memory size
  (tetra size))
;;;Flags
(tetra 5) ;read+execute
;;;Segment alignment
(tetra #x1000)
;;;
;;;DATA entry
;;;Segment type
(tetra 1) ;Loadable
;;;Segment file offset
(tetra (- asm86-data-start asm86-text-start))
;;;Segment virtual address
(tetra asm86-data-start)
;;;Segment physical address
(tetra 0) ;ignored
;;;Segment file size
(tetra (- asm86-bss-start asm86-data-start))
;;;Segment memory size
(tetra (- asm86-bss-end asm86-data-start))
;;;Flags
(tetra 7) ;read+write+execute
;;;Segment alignment
(tetra #x1000)
;;
;;Section table (Unused)
;;
(: 'section_table_start)
(align 8)
