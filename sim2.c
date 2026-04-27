/* sim2.c -- RRISC simulator, written from the Arch.md spec. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WORD_MASK  0xFFFu
#define MEM_SIZE   4096

/* Opcodes (bits 11:9) */
#define OP_AND  0
#define OP_SUB  1
#define OP_SW   2
#define OP_LW   3
#define OP_LUI  4
#define OP_ADDI 5
#define OP_ADDC 6
#define OP_SPEC 7

/* SPEC sub-opcodes (bits 2:0) */
#define RB_JALR 0
#define RB_ROR  1
#define RB_ROL  2
#define RB_LWR  3
#define RB_SWR  4

/* SIXBIT decode table: index = 6-bit value, value = output char ('\0' = silent) */
static const char sixbit_decode[64] = {
    '\0',
    'A','B','C','D','E','F','G','H','I','J',
    'K','L','M','N','O','P','Q','R','S','T',
    'U','V','W','X','Y','Z',
    '[','\\',']','^',
    '\n',
    ' ','!','"','#','$','%','&','\'','(',')','*','+',',','-','.','/',
    '0','1','2','3','4','5','6','7','8','9',
    ':',';','<','=','>','?'
};

static uint16_t mem[MEM_SIZE];
static uint16_t reg[8];
static int      T  = 0;
static uint16_t pc = 0;
static int      use_terminal = 0;
static int      use_translate = 0;

static uint16_t rdreg(int r) { return reg[r]; }

static void wrreg(int r, int val) {
    if (r != 0 && r != 7)
        reg[r] = (uint16_t)(val & WORD_MASK);
}

static uint16_t rdmem(uint16_t addr) {
    addr &= WORD_MASK;
    if (use_terminal) {
        if (addr == 07770) return 1;  /* TX RDY: always ready */
        if (addr == 07771) return 0;  /* RX RDY: never ready  */
        if (addr == 07773) return 0;  /* RX BUF: empty        */
    }
    return mem[addr];
}

static void wrmem(uint16_t addr, uint16_t val) {
    addr &= WORD_MASK;
    val  &= WORD_MASK;
    if (use_terminal && addr == 07772) {
        if (use_translate) {
            char ch = sixbit_decode[val & 0x3F];
            if (ch) { putchar(ch); fflush(stdout); }
        } else {
            putchar(val & 0xFF); fflush(stdout);
        }
        return;
    }
    if (addr >= 01000 && addr < 03000) return;  /* ROM: write-ignored */
    mem[addr] = val;
}

static int sign_extend6(int n) {
    n &= 0x3F;
    return (n & 0x20) ? (n - 64) : n;
}

static int branch_offset(int rd, int imm6) {
    return (rd == 7) ? imm6 - 64 : imm6;
}

static void load_bin(const char *filename) {
    FILE *f = fopen(filename, "rb");
    if (!f) { perror(filename); exit(1); }
    uint16_t addr = 0;
    uint8_t  buf[2];
    while (addr < MEM_SIZE && fread(buf, 1, 2, f) == 2)
        mem[addr++] = (buf[0] | ((buf[1] & 0x0F) << 8)) & WORD_MASK;
    fclose(f);
}

int main(int argc, char *argv[]) {
    int         summary  = 0;
    uint16_t    start    = 0;
    long        max_cycles = 0;
    const char *filename = NULL;

    for (int i = 1; i < argc; i++) {
        if      (strcmp(argv[i], "--summary")  == 0) summary      = 1;
        else if (strcmp(argv[i], "--terminal")  == 0) use_terminal  = 1;
        else if (strcmp(argv[i], "--translate") == 0) use_translate = 1;
        else if (strcmp(argv[i], "--start") == 0 && i + 1 < argc)
            start = (uint16_t)(strtoul(argv[++i], NULL, 8) & WORD_MASK);
        else if (strcmp(argv[i], "--maxcycle") == 0 && i + 1 < argc)
            max_cycles = strtol(argv[++i], NULL, 10);
        else filename = argv[i];
    }
    if (!filename) {
        fprintf(stderr, "usage: sim2 [--summary] [--terminal] [--translate] [--start ADDR] <binary>\n");
        return 1;
    }

    for (int i = 0; i < MEM_SIZE; i++) mem[i] = WORD_MASK;
    memset(reg, 0, sizeof(reg));
    reg[7] = WORD_MASK;

    load_bin(filename);

    pc = start;
    long running = 1, retired = 0, cycles = 0;
    while (running) {
        uint16_t ir    = rdmem(pc);
        uint16_t oldpc = pc;
        pc = (pc + 1) & WORD_MASK;

        int op  = (ir >> 9) & 7;
        int rd  = (ir >> 6) & 7;
        int ra  = (ir >> 3) & 7;
        int rb  =  ir       & 7;
        int imm =  ir       & 0x3F;
        int val, mem_op = 0;

        if (ir == WORD_MASK) {          /* halt (0o7777) */
            running = 0;
        } else switch (op) {
        case OP_AND:
            wrreg(rd, rdreg(ra) & rdreg(rb));
            break;
        case OP_SUB:
            val = (int)rdreg(ra) - (int)rdreg(rb);
            wrreg(rd, val);
            T = (val & (1 << 12)) ? 1 : 0;
            break;
        case OP_ADDC:
            val = (int)rdreg(ra) + (int)rdreg(rb) + T;
            wrreg(rd, val);
            T = (val > WORD_MASK) ? 1 : 0;
            break;
        case OP_LUI:
            if (rd == 0 || rd == 7) { if (T == 0) pc = (uint16_t)((oldpc + branch_offset(rd, imm)) & WORD_MASK); }
            else                    { wrreg(rd, imm << 6); }
            break;
        case OP_ADDI:
            if (rd == 0 || rd == 7) { if (T != 0) pc = (uint16_t)((oldpc + branch_offset(rd, imm)) & WORD_MASK); }
            else                    { wrreg(rd, (int)rdreg(rd) + sign_extend6(imm)); }
            break;
        case OP_LW:
            wrreg(1, rdmem((rdreg(rd) & 0xFC0) | (uint16_t)imm));
            mem_op = 1; break;
        case OP_SW:
            wrmem((rdreg(rd) & 0xFC0) | (uint16_t)imm, rdreg(1));
            mem_op = 1; break;
        case OP_SPEC:
            switch (rb) {
            case RB_JALR: { uint16_t t = rdreg(ra); wrreg(rd, pc); pc = t; break; }
            case RB_ROR: {
                int v = rdreg(ra), new_T = v & 1;
                wrreg(rd, (v >> 1) | (T << 11));
                T = new_T;
                break;
            }
            case RB_ROL: {
                int v = rdreg(ra), new_T = (v >> 11) & 1;
                wrreg(rd, ((v << 1) & WORD_MASK) | T);
                T = new_T;
                break;
            }
            case RB_LWR: wrreg(rd, rdmem(rdreg(ra))); mem_op = 1; break;
            case RB_SWR: wrmem(rdreg(ra), rdreg(rd)); mem_op = 1; break;
            }
            break;
        }
        retired++;
        cycles += mem_op ? 2 : 1;
        if (max_cycles > 0 && cycles >= max_cycles) {
            fprintf(stderr, "error: maxcycle %ld reached\n", max_cycles);
            return 1;
        }
    }

    if (summary) {
        printf("T: %d PC: %04o ", T, pc);
        for (int i = 0; i < 8; i++)
            printf("r%d: %04o ", i, (int)rdreg(i));
        printf("\n");
        printf("Instructions retired: %ld (%ld cycles)\n", retired, cycles);
    }
    return 0;
}
