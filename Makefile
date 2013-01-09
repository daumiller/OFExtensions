all : OFRegex

OFRegex : OFRegex.o OFRegex_test.bin

OFRegex.o : OFRegex.h OFRegex.m
	clang OFRegex.m -c -o OFRegex.o `objfw-config --objcflags`

OFRegex_test.bin : OFRegex.h OFRegex.o OFRegex_test.m
	clang OFRegex_test.m OFRegex.o -o OFRegex_test.bin -lpcre `objfw-config --objcflags --libs`

clean :
	rm -f *.o
	rm -f *.bin
