%{
// option for print trace output
#define DEBUG 0
// print trace output
#define trace(t) if (DEBUG) { cout << "trace: " << t << endl; }

#include "symbolTable.h"
#include "lex.yy.cpp"

// entire symbol tables
SymbolTables *tables = new SymbolTables();

// parsing error and exit
void yyerror(string);
// inserting symbol into symbol tables
void insertSymbolEntry(SymbolEntry* entry);
%}

%union {
    int	ival;
    float fval;
    bool bval;
    string *sval;

    SymbolValue *value;
    SymbolEntry* entry;
    int dtype;

    SymbolEntry *formal_parameter;
    vector<SymbolEntry*> *formal_parameters;

    vector<SymbolValue*> *function_arguments;
}

// tokens for scanner
%token BOOL BREAK CHAR CASE CLASS CONTINUE DECLARE DO ELSE EXIT FLOAT FOR FUN IF INT LOOP PRINT PRINTLN RETURN STRING VAL VAR WHILE READ
%token LE GE EQ NE ADDE SUBE MULE DIVE
%token IN RANGE

// return type for terminals
%token <sval> ID
%token <bval> CONST_BOOL
%token <ival> CONST_INT
%token <fval> CONST_FLOAT
%token <sval> CONST_STRING

// return type for non-terminals
%type <value> expression
%type <value> literal
%type <dtype> type
%type <formal_parameters> function_parameters
%type <formal_parameter> function_parameter
%type <function_arguments> function_arguments

// opeartor precedence
%left '|'
%left '&'
%left '!'
%left '<' LE EQ GE '>' NE
%left '+' '-'
%left '*' '/'

// debug options
%debug
%error-verbose
// entrypoint
%start program
%%

program:
    CLASS ID
    {
        trace("declare class: " + *$2);
        insertSymbolEntry(new SymbolEntry(*$2, _CLASS));
    }
    '{'
    program_body
    '}'
    {
        // find main function entry
        if (tables->lookup("main", _FUN) == NULL) {
            yyerror("main function entry not found");
        }
        // pop symbol table
        tables->dump();
        tables->popTable();
    }
    ;

program_body:
    program_body v_declarations
    | program_body statements
    | program_body function_declarations
    |
    ;

expression:
    literal
    {
        trace("expression literal");
        $$ = $1;
    }
    | ID '=' function_call
    {
        trace("expression assign function call");
        SymbolEntry *d1 = tables->lookup(*$1, -1);
        if (d1 == NULL) {
            yyerror("undefined id");
        }
    }
    | function_call
    {
        trace("expression function call");
    }
    | ID '[' expression ']'
    {
        SymbolEntry *d;
        d = tables->lookup(*$1, -1);
        if (d == NULL) {
            yyerror("undefined id");
        }
        if ($3->dtype != _INT) {
            yyerror("array indexing with non-integer index");
        }
        if ($3->ival >= d->size) {
            yyerror("array index out-of-range");
        }
        $$ = d->arr->at($3->ival);
    }
    | ID
    {
        trace("expression id");
        SymbolEntry *d = tables->lookup(*$1, _VAL);
        if (d == NULL) {
            d = tables->lookup(*$1, _VAR);
        }
        if (d == NULL) {
            yyerror("undefined id");
        } else {
            $$ = d->val;
        }
    }
    | expression '+' expression
    {
        trace("expression + expression");
        SymbolValue *d;
        if ($1->dtype == _INT || $1->dtype == _FLOAT || $3->dtype == _INT || $3->dtype == _FLOAT) {
            float v1, v2;
            if ($1->dtype == _INT) {
                v1 = $1->ival;
            } else {
                v1 = $1->fval;
            }

            if ($3->dtype == _INT) {
                v2 = $3->ival;
            } else {
                v2 = $3->fval;
            }

            d = new SymbolValue($1->dtype | $3->dtype, _VAR, v1 + v2);
        } else {
            yyerror("add arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '-' expression
    {
        trace("expression - expression");
        SymbolValue *d;
        if ($1->dtype == _INT || $1->dtype == _FLOAT || $3->dtype == _INT || $3->dtype == _FLOAT) {
            float v1, v2;
            if ($1->dtype == _INT) {
                v1 = $1->ival;
            } else {
                v1 = $1->fval;
            }

            if ($3->dtype == _INT) {
                v2 = $3->ival;
            } else {
                v2 = $3->fval;
            }

            d = new SymbolValue($1->dtype | $3->dtype, _VAR, v1 - v2);
        } else {
            yyerror("sub arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '*' expression
    {
        trace("expression * expression");
        SymbolValue *d;
        if ($1->dtype == _INT || $1->dtype == _FLOAT || $3->dtype == _INT || $3->dtype == _FLOAT) {
            float v1, v2;
            if ($1->dtype == _INT) {
                v1 = $1->ival;
            } else {
                v1 = $1->fval;
            }

            if ($3->dtype == _INT) {
                v2 = $3->ival;
            } else {
                v2 = $3->fval;
            }

            d = new SymbolValue($1->dtype | $3->dtype, _VAR, v1 * v2);
        } else {
            yyerror("mul arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '/' expression
    {
        trace("expression / expression");
        SymbolValue *d;
        if ($1->dtype == _INT || $1->dtype == _FLOAT || $3->dtype == _INT || $3->dtype == _FLOAT) {
            float v1, v2;
            if ($1->dtype == _INT) {
                v1 = $1->ival;
            } else {
                v1 = $1->fval;
            }

            if ($3->dtype == _INT) {
                v2 = $3->ival;
            } else {
                v2 = $3->fval;
            }

            d = new SymbolValue($1->dtype | $3->dtype, _VAR, v1 / v2);
        } else {
            yyerror("mul arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '>' expression
    {
        trace("expression > expression");
    }
    | expression '<' expression
    {
        trace("expression < expression");
    }
    | expression '=' expression
    {
        trace("expression = expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression GE expression
    {
        trace("expression >= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression LE expression
    {
        trace("expression <= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression EQ expression
    {
        trace("expression == expression");
    }
    | expression NE expression
    {
        trace("expression != expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression ADDE expression
    {
        trace("expression += expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression SUBE expression
    {
        trace("expression -= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression MULE expression
    {
        trace("expression *= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | expression DIVE expression
    {
        trace("expression /= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
    }
    | '-' expression
    {
        trace("- expression");
    }
    | '+' expression
    {
        trace("+ expression");
    }
    ;

literal:
    CONST_INT
    {
        trace("literal const int");
        SymbolValue *d = new SymbolValue(_INT, _VAL, $1);
        $$ = d;
    }
    | CONST_BOOL
    {
        trace("literal const bool");
        SymbolValue *d = new SymbolValue(_BOOL, _VAL, $1);
        $$ = d;
    }
    | CONST_FLOAT
    {
        trace("literal const float");
        SymbolValue *d = new SymbolValue(_FLOAT, _VAL, $1);
        $$ = d;
    }
    | CONST_STRING
    {
        trace("literal const STRING");
        SymbolValue *d = new SymbolValue(_STRING, _VAL, $1);
        $$ = d;
    }
    ;

type:
    INT
    {
        $$ = _INT;
    }
    | BOOL
    {
        $$ = _BOOL;
    }
    | FLOAT
    {
        $$ = _FLOAT;
    }
    | STRING
    {
        $$ = _STRING;
    }
    ;

// function calls
function_call:
    ID '(' function_arguments ')'
    {
        trace("function call");
        SymbolEntry *d = tables->lookup(*$1, _FUN);
        if (d == NULL) {
            yyerror("undefined function");
        }
        if (d->formal_parameters->size() != $3->size()) {
            yyerror("mismatched parameter length");
        }
        for (int i = 0; i < $3->size(); i++) {
            if (d->formal_parameters->at(i)->val->dtype != $3->at(i)->dtype) {
                yyerror("mismatched parameter dtype");
            }
        }
    }
    ;

function_arguments:
    function_arguments ',' expression
    {
        $1->push_back($3);
    }
    | expression
    {
        vector<SymbolValue*> *d = new vector<SymbolValue*>();
        d->push_back($1);
        $$ = d;
    }
    |
    {
        vector<SymbolValue*> *d = new vector<SymbolValue*>();
        $$ = d; 
    }
    ;

// variables declarations
v_declarations:
    val_declarations
    var_declarations
    ;

val_declarations:
    val_declaration val_declarations
    |
    ;

val_declaration:
    VAL ID '=' expression
    {
        trace("val decalaration");
        SymbolEntry *d;
        d = tables->lookup(*$2, -1);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _VAL);
        d->val = $4;
        insertSymbolEntry(d);
    }
    | VAL ID ':' type '=' expression
    {
        trace("val decalaration with type");
        if ($4 != $6->dtype) {
            yyerror("val decalaration with wrong type");
        }
        SymbolEntry *d;
        d = tables->lookup(*$2, -1);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _VAL);
        d->val = $6;
        insertSymbolEntry(d);
    }
    ;

var_declarations:
    var_declaration var_declarations
    |
    ;

var_declaration:
    VAR ID '=' expression
    {
        trace("var decalaration with value");
        SymbolEntry *d;
        d = tables->lookup(*$2, _ALL);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _VAR);
        d->val = $4;
        insertSymbolEntry(d);
    }
	| VAR ID ':' type '=' expression
    {
        trace("var decalaration with type");
        SymbolEntry *d;
        d = tables->lookup(*$2, _ALL);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _VAR);
        d->val = $6;
        insertSymbolEntry(d);
    }
	| VAR ID ':' type
    {
        trace("var decalaration with type without value");
        SymbolEntry *d;
        d = tables->lookup(*$2, _ALL);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _VAR);
        d->val = new SymbolValue();
        d->val->dtype = $4;
        insertSymbolEntry(d);
    }
	| VAR ID ':' type '[' CONST_INT ']'
    {
        trace("var array decalaration");
        SymbolEntry *d;
        d = tables->lookup(*$2, _ALL);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _ARRAY);
        d->val = new SymbolValue();
        d->val->dtype = $4;
        d->size = $6;
        d->arr = new vector<SymbolValue*>();
        // init array to avoid segmentation fault
        for (int i = 0; i < $6; i++) {
            d->arr->push_back(new SymbolValue);
        }
        insertSymbolEntry(d);
    }
    ;

statements:
    statement statements
    |
    ;

statement:
    expression
    {
        trace("statement expression");
    }
    | ID '=' expression
    {
        trace("statement id = expression");
    }
    |
    '{'
    {
        trace("statement start block");
        tables->pushTable();
    }
    function_body_block '}'
    {
        trace("statement end block");
        // dump and pop
        tables->dump();
        tables->popTable();
    }
    | condition
    {
        trace("statement condition");
    }
    | loop
    {
        trace("statement loop");
    }
    | PRINT expression
    {
        trace("statement print");
    }
    | PRINTLN expression
    {
        trace("statement println");
    }
    | PRINT '(' expression ')'
    {
        trace("statement print");
    }
    | PRINTLN '(' expression ')'
    {
        trace("statement println");
    }
    | READ expression
    {
        trace("statement read");
    }
    | RETURN
    {
        trace("statement return");
    }
    | RETURN expression
    {
        trace("statement return expression");
    }
    ;

// function declarations
function_declarations:
    function_declaration function_declarations
    |
    ;

function_declaration:
    FUN ID '(' function_parameters ')'
    {
        trace("declare function: " + *$2);
        SymbolEntry *d = new SymbolEntry(*$2, _FUN);
        insertSymbolEntry(d);
        // function parameters
        d->formal_parameters = $4;
        // push
        tables->pushTable();
    }
    function_body
    {
        // dump and pop
        tables->dump();
        tables->popTable();
    }
    | FUN ID '(' function_parameters ')' ':' type
    {
        trace("declare function with return type: " + *$2);
        SymbolEntry *d = new SymbolEntry(*$2, _FUN);
        insertSymbolEntry(d);
        // function paramters
        d->formal_parameters = $4;
        // push
        tables->pushTable();
    }
    function_body
    {
        // dump and pop
        tables->dump();
        tables->popTable();
    }
    ;

function_parameters:
    // store parameters for checking
    function_parameters ',' function_parameter
    {
        $1->push_back($3);
    }
    | function_parameter
    {
        auto d = new vector<SymbolEntry*>();
        d->push_back($1);
        $$ = d;
    }
    |
    {
        $$ = new vector<SymbolEntry*>();
    }
    ;

function_parameter:
    ID ':' type
    {
        // store parameter with type as an entry
        trace("function param: " + *$1 + ", type: " + std::to_string($3));
        SymbolEntry *d = new SymbolEntry;
        d->name = *$1;
        d->val = new SymbolValue;
        d->val->dtype = $3;
        $$ = d;
    }
    ;

function_body:
    '{'
    function_body_block
    '}'
    ;

function_body_block:
    function_body_block statement
    | function_body_block v_declarations
    |
    ;

// condition
condition:
    IF '(' expression ')'
    condition_body
    ELSE
    condition_body
    {
        trace("condition if else");
    }
    | 
    IF '(' expression ')'
    condition_body
    {
        trace("condition if");
    }
    ;

condition_body:
    '{'
    statements
    '}'
    | statements
    ;

// loop
loop:
    WHILE '(' expression ')'
    {
        trace("loop while");
    }
    '{'
    statements
    '}'
    |
    FOR '(' ID IN expression RANGE expression ')'
    {
        trace("loop for");
        SymbolEntry *d = new SymbolEntry(*$3, _VAR);
        d->val = $5;
        // insert variable for looping
        insertSymbolEntry(d);
    }
    '{'
    statements
    '}'
    ;


%%
void yyerror(string msg) {
    cout << "yyerror: " << msg << endl;
    exit(-1);
}

void insertSymbolEntry(SymbolEntry *entry) {
    if (!tables->insert(entry)) {
        yyerror("error: insert symbol entry");
    }
}

int main(int argc, char* argv[]) {
    /* open the source program file */
    if (argc == 1) {
        yyin = stdin;
    } else if (argc == 2) {
        yyin = fopen(argv[1], "r");         /* open input file */
    } else {
        printf("Usage: ./parser filename\n");
        exit(1);
    }
    
    /* perform parsing */
    if (yyparse() == 1)
        yyerror("Parsing error !");
    else
        cout << "Parsed succeed!" << endl;
}
