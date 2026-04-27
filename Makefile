
CC      = cc
CFLAGS  = -O2 -Wall

sim2: sim2.c
	$(CC) $(CFLAGS) -o $@ $<

examples: 
	for src in examples/*.s; do \
		python asm.py "$$src" || exit 1; \
	done

clean:
	-rm -f sim2 *.bin tests/*.bin tests/*.output tests/*.sim2.output tests/*.err 
	-rm -f examples/*.bin examples/*.output examples/*.sim2.output

