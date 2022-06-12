%{
#define MAX_LINE_LENGTH 256
#define MAX_SYMBOL_NUMBER 1024
#define MAX_SYMBOL_STRING_LENGTH 256

#include "symbolTable.h"
#include "y.tab.hpp"

#define LIST strcat(lineBuffer, yytext)
#define token(t) {LIST; if (DEBUG) { cout << "<" << #t << ">" << endl;} return t;}
#define tokenOperator(t) {LIST; if (DEBUG) { printf("<operator:'%s'>\n", t); } return t[0];}
#define tokenDelimiter(t) {LIST; if (DEBUG) { printf("<delimiter:'%s'>\n", t); } return t[0];}
#define tokenString(t,s) {LIST; if(DEBUG) { printf("<%s:%s>\n", #t, s); }}
#define printLine {printf("%d: %s", yylineno - 1, lineBuffer);}

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

char lineBuffer[MAX_LINE_LENGTH];
%}

operator        "+"|"-"|"*"|"/"|"%"|"<"|"<="|">"|">="|"=="|"!="|"&"|"|"|"!"|"="|"+="|"-="|"*="|"/="
delimiter       ","|":"|";"|"->"|"("|")"|"["|"]"|"{"|"}"
identifier      [a-zA-Z][a-zA-Z0-9]*
stringConstant  \".*\"

%option yylineno noyywrap
%x LINE_COMMENT BLOCK_COMMENT
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

<INITIAL>"bool" {token(BOOL);}
<INITIAL>"break" {token(BREAK);}
<INITIAL>"char" {token(CHAR);}
<INITIAL>"case" {token(CASE);}
<INITIAL>"class" {token(CLASS);}
<INITIAL>"continue" {token(CONTINUE);}
<INITIAL>"declare" {token(DECLARE);}
<INITIAL>"do" {token(DO);}
<INITIAL>"else" {token(ELSE);}
<INITIAL>"exit" {token(EXIT);}
<INITIAL>"float" {token(FLOAT);}
<INITIAL>"for" {token(FOR);}
<INITIAL>"fun" {token(FUN);}
<INITIAL>"if" {token(IF);}
<INITIAL>"int" {token(INT);}
<INITIAL>"loop" {token(LOOP);}
<INITIAL>"print" {token(PRINT);}
<INITIAL>"println" {token(PRINTLN);}
<INITIAL>"return" {token(RETURN);}
<INITIAL>"string" {token(STRING);}
<INITIAL>"val" {token(VAL);}
<INITIAL>"var" {token(VAR);}
<INITIAL>"while" {token(WHILE);}
<INITIAL>"read" {token(READ);}

<INITIAL>"<=" {token(LE);}
<INITIAL>">=" {token(GE);}
<INITIAL>"==" {token(EQ);}
<INITIAL>"!=" {token(NE);}
<INITIAL>"+=" {token(ADDE);}
<INITIAL>"-=" {token(SUBE);}
<INITIAL>"*=" {token(MULE);}
<INITIAL>"/=" {token(DIVE);}

<INITIAL>"true"  {yylval.bval = true; tokenString(boolean, yytext); return CONST_BOOL;}
<INITIAL>"false"  {yylval.bval = false; tokenString(boolean, yytext); return CONST_BOOL;}

<INITIAL>[+-]?[0-9]+ {yylval.ival = atoi(yytext); tokenString(int, yytext); return CONST_INT;}
<INITIAL>[+-]?[0-9]+\.[0-9]+ {yylval.fval = atof(yytext); tokenString(float, yytext); return CONST_FLOAT;}
<INITIAL>[+-]?[0-9]+([Ee][+\-]?[1-9][0-9]*)? {yylval.fval = atof(yytext); tokenString(float, yytext); return CONST_FLOAT;}

<INITIAL>"in" {token(IN);}
<INITIAL>".." {token(RANGE);}

<INITIAL>{operator}         {tokenOperator(yytext);}
<INITIAL>{delimiter}        {tokenDelimiter(yytext); return yytext[0];}
<INITIAL>{stringConstant}   {tokenString(string, trimStringConstant(yytext)); yylval.sval = new string(yytext); return CONST_STRING;}
<INITIAL>{identifier}       {tokenString(id, yytext); yylval.sval = new string(yytext); return ID;}

<INITIAL>"\n"   {
                LIST;
                printLine;
                lineBuffer[0] = '\0';
                }
<INITIAL>[ \t]* {LIST;}
<INITIAL>[^\n]  {
                LIST;
                printLine;
                printf("\nbad character:'%s'\n",yytext);
                exit(-1);
                }
%%
