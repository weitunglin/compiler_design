all:
	lex lex.l && gcc -o scanner lex.yy.c -ll && rm lex.yy.c

clean:
	rm -f lex.yy.c scanner
