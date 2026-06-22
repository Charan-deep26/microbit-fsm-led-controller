.syntax unified
.cpu cortex-m4
.thumb
.global main
.type main, %function

@ ═══════════════════════════════════════════════════════════════════════
@ micro:bit V2 (nRF52833) — 8 patterns, button-cycled
@
@ GPIO banks:
@   R0 = 0x50000000  (GPIO0) — ROW1-5, COL1, COL2, COL3, COL5
@   R1 = 0x50000300  (GPIO1) — COL4 only (P1.05 = bit 5 = 0x00000020)
@
@ Column bit mapping in pattern bytes (bits 0-4):
@   bit0=COL1  bit1=COL2  bit2=COL3  bit3=COL4  bit4=COL5
@
@ Buttons:
@   Button A = P0.14 (bit 14 = 0x00004000) → previous pattern
@   Button B = P0.23 (bit 23 = 0x00800000) → next pattern
@ ═══════════════════════════════════════════════════════════════════════

.data
.align 2

@ ── PLUS ──────────────────────────────────────────────────────────────
@   ..h..  0x04
@   ..h..  0x04
@   hhhhh  0x1F
@   ..h..  0x04
@   ..h..  0x04
plus_pattern:
.byte 0x04, 0x04, 0x1F, 0x04, 0x04

@ ── CROSS (X) ────────────────────────────────────────────────────────
@   h...h  0x11
@   .h.h.  0x0A
@   ..h..  0x04
@   .h.h.  0x0A
@   h...h  0x11
cross_pattern:
.byte 0x11, 0x0A, 0x04, 0x0A, 0x11

@ ── DIAMOND ───────────────────────────────────────────────────────────
@   ..h..  0x04
@   .h.h.  0x0A
@   h...h  0x11
@   .h.h.  0x0A
@   ..h..  0x04
diamond_pattern:
.byte 0x04, 0x0A, 0x11, 0x0A, 0x04

@ ── CHECKERBOARD ──────────────────────────────────────────────────────
@   .h.h.  0x0A
@   h.h.h  0x15
@   .h.h.  0x0A
@   h.h.h  0x15
@   .h.h.  0x0A
checker_pattern:
.byte 0x0A, 0x15, 0x0A, 0x15, 0x0A

@ ── PYRAMID ───────────────────────────────────────────────────────────
@   .....  0x00
@   ..h..  0x04
@   .hhh.  0x0E
@   hhhhh  0x1F
@   .....  0x00
pyramid_pattern:
.byte 0x00, 0x04, 0x0E, 0x1F, 0x00

@ ── SMILEY ────────────────────────────────────────────────────────────
@   .h.h.  0x0A  (eyes)
@   .h.h.  0x0A  (eyes)
@   .....  0x00
@   h...h  0x11  (mouth corners)
@   .hhh.  0x0E  (mouth curve)
smiley_pattern:
.byte 0x0A, 0x0A, 0x00, 0x11, 0x0E

@ ── HOUSE ─────────────────────────────────────────────────────────────
@   ..h..  0x04
@   .hhh.  0x0E
@   hhhhh  0x1F
@   hh.hh  0x1B
@   hh.hh  0x1B
house_pattern:
.byte 0x04, 0x0E, 0x1F, 0x1B, 0x1B

@ ── HEART ─────────────────────────────────────────────────────────────
@   .h.h.  C2+C4      = 0x0A
@   hhhhh  C1-C5      = 0x1F
@   .hhh.  C2+C3+C4   = 0x0E
@   ..h..  C3         = 0x04
@   .....             = 0x00
heart_pattern:
.byte 0x0A, 0x1F, 0x0E, 0x04, 0x00

@ ── Pattern pointer table ──────────────────────────────────────────────
.align 2
pattern_table:
.word plus_pattern
.word cross_pattern
.word diamond_pattern
.word checker_pattern
.word pyramid_pattern
.word smiley_pattern
.word house_pattern
.word heart_pattern

.align 2

@ ════════════════════════════════════════════════════════════════════════
.section .text
main:
    LDR  R0, =0x50000000        @ GPIO0 base
    LDR  R1, =0x50000300        @ GPIO1 base

    @ ── Set all LED pins as output ──────────────────────────────────
    LDR  R2, =0xD1688800        @ GPIO0: rows + COL1,COL2,COL3,COL5
    STR  R2, [R0, #0x518]       @ GPIO0 DIRSET
    LDR  R2, =0x00000020        @ GPIO1: COL4
    STR  R2, [R1, #0x518]       @ GPIO1 DIRSET

    @ ── Configure button pins as input ─────────────────────────────────
    MOV  R2, #0
    STR  R2, [R0, #0x738]       @ PIN_CNF[14] Button A — input
    STR  R2, [R0, #0x75C]       @ PIN_CNF[23] Button B — input

    @ ── R6 = current pattern index ──────────────────────────────────
    MOV  R6, #0

@ ════════════════════════════════════════════════════════════════════════
@ MAIN LOOP — draw current pattern, poll buttons to change it
@   Button B → next pattern
@   Button A → previous pattern
@ ════════════════════════════════════════════════════════════════════════
main_loop:
    @ ── Draw one full scan of current pattern ────────────────────────
    LDR  R4, =pattern_table
    LSL  R7, R6, #2             @ index * 4
    LDR  R4, [R4, R7]           @ R4 = pointer to 5-byte pattern

    MOV  R8, #0
row_scan:
    LDRB R9, [R4, R8]
    BL   draw_row
    BL   delay_mux
    ADD  R8, R8, #1
    CMP  R8, #5
    BLT  row_scan

    @ ── Poll buttons ─────────────────────────────────────────────────
    LDR  R2, [R0, #0x510]       @ read GPIO0 IN

    LDR  R3, =0x00004000        @ Button A = P0.14
    TST  R2, R3
    BEQ  go_prev                @ bit LOW = pressed

    LDR  R3, =0x00800000        @ Button B = P0.23
    TST  R2, R3
    BEQ  go_next                @ bit LOW = pressed

    B    main_loop

go_next:
    ADD  R6, R6, #1
    CMP  R6, #8
    BLT  do_debounce
    MOV  R6, #0
    B    do_debounce

go_prev:
    SUBS R6, R6, #1
    BGE  do_debounce
    MOV  R6, #7
    B    do_debounce

do_debounce:
    BL   delay_debounce
wait_release:
    LDR  R2, [R0, #0x510]
    LDR  R3, =0x00804000        @ both button bits
    AND  R4, R2, R3
    CMP  R4, R3
    BNE  wait_release           @ wait until both HIGH (released)
    BL   delay_debounce
    B    main_loop

@ ────────────────────────────────────────────────────────────────────────
@ draw_row — light cols in R9 for row R8
@   R9 bits: 0=COL1  1=COL2  2=COL3  3=COL4  4=COL5
@   COL active = pin LOW  → OUTCLR (0x50C)
@   ROW active = pin HIGH → OUTSET (0x508)
@ ────────────────────────────────────────────────────────────────────────
draw_row:
    PUSH {LR}
    BL   clear_leds

    @ ── Columns ─────────────────────────────────────────────────────
    TST  R9, #1                 @ COL1 = P0.28
    BEQ  skip_c1
    LDR  R2, =0x10000000
    STR  R2, [R0, #0x50C]
skip_c1:
    TST  R9, #2                 @ COL2 = P0.11
    BEQ  skip_c2
    LDR  R2, =0x00000800
    STR  R2, [R0, #0x50C]
skip_c2:
    TST  R9, #4                 @ COL3 = P0.31
    BEQ  skip_c3
    LDR  R2, =0x80000000
    STR  R2, [R0, #0x50C]
skip_c3:
    TST  R9, #8                 @ COL4 = P1.05 → GPIO1
    BEQ  skip_c4
    LDR  R2, =0x00000020
    STR  R2, [R1, #0x50C]
skip_c4:
    TST  R9, #16                @ COL5 = P0.30
    BEQ  skip_c5
    LDR  R2, =0x40000000
    STR  R2, [R0, #0x50C]
skip_c5:

    @ ── Row ─────────────────────────────────────────────────────────
    CMP  R8, #0
    BNE  check_r1
    LDR  R2, =0x00200000        @ ROW1 = P0.21
    STR  R2, [R0, #0x508]
    B    row_done
check_r1:
    CMP  R8, #1
    BNE  check_r2
    LDR  R2, =0x00400000        @ ROW2 = P0.22
    STR  R2, [R0, #0x508]
    B    row_done
check_r2:
    CMP  R8, #2
    BNE  check_r3
    LDR  R2, =0x00008000        @ ROW3 = P0.15
    STR  R2, [R0, #0x508]
    B    row_done
check_r3:
    CMP  R8, #3
    BNE  check_r4
    LDR  R2, =0x01000000        @ ROW4 = P0.24
    STR  R2, [R0, #0x508]
    B    row_done
check_r4:
    LDR  R2, =0x00080000        @ ROW5 = P0.19
    STR  R2, [R0, #0x508]
row_done:
    POP  {PC}

@ ────────────────────────────────────────────────────────────────────────
@ clear_leds — all rows LOW, all cols HIGH (nothing lit)
@ ────────────────────────────────────────────────────────────────────────
clear_leds:
    LDR  R2, =0x01688000        @ all row pins
    STR  R2, [R0, #0x50C]       @ rows LOW (OUTCLR)
    LDR  R2, =0xD0000800        @ COL1,COL2,COL3,COL5 on GPIO0
    STR  R2, [R0, #0x508]       @ cols HIGH (OUTSET = inactive)
    LDR  R2, =0x00000020        @ COL4 on GPIO1
    STR  R2, [R1, #0x508]       @ COL4 HIGH (inactive)
    BX   LR

@ ────────────────────────────────────────────────────────────────────────
@ delay_mux — ~2ms per row for persistence of vision
@ ────────────────────────────────────────────────────────────────────────
delay_mux:
    LDR  R2, =4000
dm_loop:
    SUBS R2, R2, #1
    BNE  dm_loop
    BX   LR

@ ────────────────────────────────────────────────────────────────────────
@ delay_debounce — ~50ms debounce delay
@ ────────────────────────────────────────────────────────────────────────
delay_debounce:
    LDR  R2, =100000
db_loop:
    SUBS R2, R2, #1
    BNE  db_loop
    BX   LR 
