%{
    #include <string.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <ctype.h>
    #define MAX_LINE_LENGTH 256
    #define MAX_SYMBOL_NUMBER 1000
    #define MAX_SYMBOL_STRING_LENGTH 256

    #define LIST strcat(lineBuffer, yytext)
    #define token(t) {LIST; printf("<%s>\n", t);}
    #define tokenOperator(t) {LIST; printf("<'%s'>\n", t);}
    #define tokenDelimiter(t) {LIST; printf("<'%s'>\n", t);}
    #define tokenInteger(t,i) {LIST; printf("<%s:%d>\n", #t, i);}
    #define tokenString(t,s) {LIST; printf("<%s:%s>\n", #t, s);}
    #define printLine {printf("%d: %s", lineNumber++, lineBuffer);}

    char* trimStringConstant(char* str) {
        int len = strlen(str);
        int i = 0, j = 1;
        for (; j < len - 1;) {
            str[i++] = str[j++];
            if (str[j] == '"') {
                ++j;
            }
        }
        str[i] = '\0';

        return str;
    }

    char* toUpper(char* str) {
        int len = strlen(str);
        int i = 0;
        for (; i < len; i++) {
            str[i] = toupper(str[i]);
        }

        return str;
    }

    int lineNumber = 1;
    int symbolNumber = 0;
    char lineBuffer[MAX_LINE_LENGTH];
    char **symbolTable;

    void createSymbolTable() {
        int i = 0;
        symbolTable = (char**)(malloc(MAX_SYMBOL_NUMBER * sizeof(char*)));
        for (; i < MAX_SYMBOL_NUMBER; i++) {
            symbolTable[i] = (char*)(malloc(MAX_SYMBOL_STRING_LENGTH * sizeof(char)));
        }
    }

    int lookupSymbol(char* name) {
        int i = 0;
        for (; i < symbolNumber; i++) {
            if (strcmp(symbolTable[i], name) == 0) {
                return i;
            }
        }

        return -1;
    }
    
    int insertSymbol(char* name) {
        if (lookupSymbol(name) == -1) {
            strcpy(symbolTable[symbolNumber++], name);
            // printf("inserting %s %lu\n", name, strlen(name));
        }

        return symbolNumber;
    }

    void dumpSymbolTable() {
        printf("\nSymbol Table:\n");

        int i = 0;
        for (; i < symbolNumber; i++) {
            printf("%s\n", symbolTable[i]);
        }

        printf("\n");
    }
%}

keyword         (bool|break|char|case|class|continue|declare|do|else|exit|float|for|fun|if|int|loop|print|println|return|string|val|var|while)
operator        "+"|"-"|"*"|"/"|"%"|"<"|"<="|">"|">="|"=="|"!="|"&"|"|"|"!"|"="|"+="|"-="|"*="|"/="
delimiter       ","|":"|";"|"->"|"("|")"|"["|"]"|"{"|"}"
identifier      [a-zA-Z][a-zA-Z0-9]*
integerConstant [0-9]+
booleanConstant "true"|"false"
realConstant    [+-]?[\d]+
stringConstant  \".*\"

%Start LINE_COMMENT BLOCK_COMMENT
%%

<INITIAL>"//"           {LIST; BEGIN LINE_COMMENT;}
<LINE_COMMENT>.         {LIST;}
<LINE_COMMENT>"\n"      {LIST; printLine; lineBuffer[0] = '\0'; BEGIN INITIAL;}

<INITIAL>"/*"           {LIST; BEGIN BLOCK_COMMENT;}
<BLOCK_COMMENT>[^\n]    {LIST;}
<BLOCK_COMMENT>"\n"     {LIST; printLine; lineBuffer[0] = '\0';}
<BLOCK_COMMENT>"*/"     {
                        LIST;
                        BEGIN INITIAL;
                        }

<INITIAL>{keyword}          {token(toUpper(yytext));}
<INITIAL>{operator}         {tokenOperator(yytext);}
<INITIAL>{delimiter}        {tokenDelimiter(yytext);}
<INITIAL>{integerConstant}  {tokenInteger(int, atoi(yytext));}
<INITIAL>{booleanConstant}  {tokenString(boolean, toUpper(yytext));}
<INITIAL>{realConstant}     {tokenInteger(real, atoi(yytext));}
<INITIAL>{stringConstant}   {tokenString(string, trimStringConstant(yytext));}
<INITIAL>{identifier}       {tokenString(id, yytext); insertSymbol(yytext);}

<INITIAL>"\n"   {
                LIST;
                printLine;
                lineBuffer[0] = '\0';
                }
<INITIAL>[ \t]* {LIST;}
<INITIAL>[^\n]  {LIST;}
%%

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: ./scanner HelloWorld.kt\n");
        return -1;
    }
	
    FILE *inputFile = fopen(argv[1], "r");
    if (inputFile == NULL) {
        fprintf(stderr, "Cannot open file, please check your file again.\n");
        return -1;
    }
	
    yyin = inputFile;

    createSymbolTable();

    yylex();

    if (strlen(lineBuffer) != 0) {
        printLine;
        printf("\n");
    }

    dumpSymbolTable();

    return 0;
}
