CC = g++
CFLAG = -ll -DDEBUG -g -std=c++11 -DYYDEBUG

LEX_SOURCE = scanner.l
YACC_SOURCE = parser.y
SYMBOL_TABLE_SOURCE = symbolTable.cpp

all: compile

compile: yacc lex $(SYM_TABLE_SOURCE)
	$(CC) y.tab.cpp $(SYM_TABLE_SOURCE) -o parser $(CFLAG)

yacc: $(YACC_SOURCE)
	yacc -d -t -v $(YACC_SOURCE) -o y.tab.cpp

lex: $(LEX_SOURCE)
	lex -o lex.yy.cpp $(LEX_SOURCE)

.PHONY: clean

clean:
	- rm -f y.tab.*
	- rm -f *.o
	- rm -f lex.yy.*
	- rm -f *.output
	- rm -f parser
