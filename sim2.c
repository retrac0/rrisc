/* sim2.c -- RRISC simulator, written from the Arch.md spec. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WORD_MASK  0xFFFu

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

/* Memory bank types */
#define BANK_RAM 0
#define BANK_ROM 1
#define BANK_IO  2
#define MAX_BANKS 16

typedef struct {
    int      type;
    uint16_t base;
    uint16_t size;
    uint16_t *data;
} Bank;

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

static Bank     banks[MAX_BANKS];
static int      num_banks  = 0;
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

/* Parse an address string: handles 0o-prefixed octal, 0x-prefixed hex, or decimal. */
static uint16_t parse_addr(const char *s) {
    if (s[0] == '0' && (s[1] == 'o' || s[1] == 'O'))
        return (uint16_t)(strtoul(s + 2, NULL, 8) & WORD_MASK);
    return (uint16_t)(strtoul(s, NULL, 0) & WORD_MASK);
}

/* Parse "TYPE:BASE:SIZE" and append to the banks array. Returns 1 on success. */
static int parse_bank_spec(const char *spec) {
    if (num_banks >= MAX_BANKS) { fprintf(stderr, "too many --mem banks (max %d)\n", MAX_BANKS); return 0; }
    char buf[64];
    strncpy(buf, spec, sizeof(buf) - 1);
    buf[sizeof(buf) - 1] = '\0';
    char *tok = strtok(buf, ":");
    if (!tok) { fprintf(stderr, "--mem: missing type in %s\n", spec); return 0; }
    int type;
    if      (strcmp(tok, "ram") == 0) type = BANK_RAM;
    else if (strcmp(tok, "rom") == 0) type = BANK_ROM;
    else if (strcmp(tok, "io")  == 0) type = BANK_IO;
    else { fprintf(stderr, "--mem: unknown bank type '%s'\n", tok); return 0; }
    tok = strtok(NULL, ":");
    if (!tok) { fprintf(stderr, "--mem: missing base in %s\n", spec); return 0; }
    uint16_t base = parse_addr(tok);
    tok = strtok(NULL, ":");
    if (!tok) { fprintf(stderr, "--mem: missing size in %s\n", spec); return 0; }
    uint16_t size = parse_addr(tok);
    banks[num_banks++] = (Bank){type, base, size, NULL};
    return 1;
}

static void add_default_banks(void) {
    banks[num_banks++] = (Bank){BANK_RAM, 0,     0100,  NULL};  /* 64 words  */
    banks[num_banks++] = (Bank){BANK_ROM, 01000, 02000, NULL};  /* 1024 words */
}

static void init_banks(void) {
    for (int i = 0; i < num_banks; i++) {
        if (banks[i].type == BANK_IO) { banks[i].data = NULL; continue; }
        banks[i].data = (uint16_t *)malloc(banks[i].size * sizeof(uint16_t));
        if (!banks[i].data) { perror("malloc"); exit(1); }
        for (int j = 0; j < banks[i].size; j++)
            banks[i].data[j] = WORD_MASK;
    }
}

static uint16_t rdmem(uint16_t addr) {
    addr &= WORD_MASK;
    if (use_terminal) {
        if (addr == 07770) return 1;  /* TX RDY: always ready */
        if (addr == 07771) return 0;  /* RX RDY: never ready  */
        if (addr == 07773) return 0;  /* RX BUF: empty        */
    }
    for (int i = 0; i < num_banks; i++) {
        uint16_t end = (uint16_t)(banks[i].base + banks[i].size);
        if (addr >= banks[i].base && addr < end) {
            if (banks[i].type == BANK_IO) return 0;
            return banks[i].data[addr - banks[i].base];
        }
    }
    return WORD_MASK;  /* floating */
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
    for (int i = 0; i < num_banks; i++) {
        uint16_t end = (uint16_t)(banks[i].base + banks[i].size);
        if (addr >= banks[i].base && addr < end) {
            if (banks[i].type == BANK_RAM)
                banks[i].data[addr - banks[i].base] = val;
            return;  /* ROM: write ignored; IO: no backing store */
        }
    }
    /* unmapped: silently ignored */
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
    while (fread(buf, 1, 2, f) == 2) {
        uint16_t word = (buf[0] | ((buf[1] & 0x0F) << 8)) & WORD_MASK;
        for (int i = 0; i < num_banks; i++) {
            uint16_t end = (uint16_t)(banks[i].base + banks[i].size);
            if (addr >= banks[i].base && addr < end) {
                if (banks[i].data != NULL)
                    banks[i].data[addr - banks[i].base] = word;
                break;
            }
        }
        addr = (addr + 1) & WORD_MASK;
    }
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
        else if (strcmp(argv[i], "--mem") == 0 && i + 1 < argc)
            parse_bank_spec(argv[++i]);
        else filename = argv[i];
    }
    if (!filename) {
        fprintf(stderr, "usage: sim2 [--summary] [--terminal] [--translate] [--start ADDR] [--mem TYPE:BASE:SIZE] <binary>\n");
        return 1;
    }

    if (num_banks == 0) add_default_banks();
    init_banks();
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
            T = (val > (int)WORD_MASK) ? 1 : 0;
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
