; rrisc_float_bundle.s — one translation unit for soft-float + itoa, built as a
; single relocatable object (hsasm --emit-obj) and linked with hsld after RCC output.
;
; Export linker-visible entry points (C-like global linkage). Internal helpers
; stay file-local unless given .global in their source file.
.global __fcopy
.global __fneg
.global __fadd
.global __fsub
.global __fmul
.global __fdiv
.global __fcmp
.global __ftoi
.global __itof
.global __atof
.global itoa
.global __ftoa

; shared helpers (used by multiple float routines)
%include "float/_float_store_helpers.s"

%include "float/__fcopy.s"
%include "float/__fneg.s"
%include "float/__fadd.s"
%include "float/__fsub.s"
%include "float/__fmul.s"
%include "float/__fdiv.s"
%include "float/__fcmp.s"
%include "float/__ftoi.s"
%include "float/__itof.s"
%include "float/__atof.s"
%include "itoa.s"
%include "float/__ftoa.s"
