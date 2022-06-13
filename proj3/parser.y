%{
// option for print trace output
#define DEBUG 0
// print trace output
#define trace(t) if (DEBUG) { cout << "trace: " << t << endl; }

#include "symbolTable.h"
#include "lex.yy.cpp"

// entire symbol tables
SymbolTables *tables = new SymbolTables();

// used for generating java byte code
ofstream os;
// used for local variable stack counter
int stack_number = 0;
// base for static variable name
string class_name;
// layers for condition, loop
int last_index = -1;
stack<int> layers;

// parsing error and exit
void yyerror(string);
// inserting symbol into symbol tables
void insertSymbolEntry(SymbolEntry* entry);
// getting tab size in output jasm
string getT(void);
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
%type <entry> function_call

// opeartor precedence
%left '|'
%left '&'
%left '!'
%left '<' LE EQ GE '>' NE
%left '+' '-'
%left '*' '/'

// entrypoint
%start program
%%

program:
    CLASS ID
    {
        trace("declare class: " + *$2);
        insertSymbolEntry(new SymbolEntry(*$2, _CLASS));
        os << "class " << *$2 << endl << "{" << endl;
        class_name = *$2;
    }
    '{'program_body
    
    '}'
    {
        // find main function entry
        if (tables->lookup("main", _FUN) == NULL) {
            yyerror("main function entry not found");
        }
        // pop symbol table
        tables->dump();
        tables->popTable();
        os << "}" << endl;
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
        $$ = new SymbolValue(*$1);
        if (!tables->inGlobal()) {
            os << getT();
            if ($1->dtype == _INT) {
                os << "sipush " << std::to_string($1->ival);
            } else if ($1->dtype == _BOOL) {
                os << "iconst_" << $1->bval ? "1" : "0";
            } else if ($1->dtype == _STRING) {
                os << "ldc \"" << *$1->sval << "\"";
            }
            os << endl;
        }
    }
    | ID '=' function_call
    {
        trace("expression assign function call");
        SymbolEntry *d1 = tables->lookup(*$1, -1);
        if (d1 == NULL) {
            yyerror("undefined id");
        }
        SymbolValue *d = new SymbolValue();
        d->dtype = $3->return_dtype;
        d->type = _VAR;
        if (d1->val->dtype != d->dtype) {
            yyerror("assign without same type");
        }
        if (tables->lookup(*$1, _VAR, true)) {
            // global var
            os << getT() << "putstatic " << toDtypeString($3->return_dtype) << " " << class_name << "." << *$1 << endl;
        } else {
            // local var
            os << getT() << "istore " << std::to_string(d1->val->id) << endl;
        }
        $$ = d;
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
        trace("expression id" + *$1);
        SymbolEntry *d = tables->lookup(*$1, _VAR);
        if (d == NULL) {
            d = tables->lookup(*$1, _VAL);
        }
        if (d == NULL) {
            yyerror("undefined id" + *$1);
        } else {
            $$ = d->val;
        }
        if (d->type == _VAL) {
            if (d->val->dtype == _INT) {
                os << getT() << "sipush " << std::to_string(d->val->ival) << endl;
            } else if (d->val->dtype == _BOOL) {
                os << getT() << "iconst_ " << (d->val->bval ? "1" : "0") << endl;
            }
        } else if (d->type == _VAR) {
            if (tables->lookup(*$1, _VAR, true)) {
                // global var
                os << getT() << "getstatic " << toDtypeString(d->val->dtype) << " "
                << class_name << "." << d->name << endl;
            } else {
                // local var
                os << getT() << "iload " << d->val->id << endl;
            }
        }
    }
    | expression '+' expression
    {
        trace("expression + expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype == _INT && $3->dtype == _INT) {
            d->dtype = _INT;
            int v1, v2;
            v1 = $1->ival;
            v2 = $3->ival;
            os << getT() << "iadd" << endl;
        } else {
            yyerror("add arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '-' expression
    {
        trace("expression - expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype == _INT && $3->dtype == _INT) {
            d->dtype = _INT;
            int v1, v2;
            v1 = $1->ival;
            v2 = $3->ival;
            os << getT() << "isub" << endl;
        } else {
            yyerror("sub arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '*' expression
    {
        trace("expression * expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype == _INT && $3->dtype == _INT) {
            d->dtype = _INT;
            int v1, v2;
            v1 = $1->ival;
            v2 = $3->ival;
            os << getT() << "imul" << endl;
        } else {
            yyerror("mul arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '/' expression
    {
        trace("expression / expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype == _INT && $3->dtype == _INT) {
            d->dtype = _INT;
            int v1, v2;
            v1 = $1->ival;
            v2 = $3->ival;
            os << getT() << "idiv" << endl;
        } else {
            yyerror("mul arithmetic with unsupported type");
        }
        $$ = d;
    }
    | expression '>' expression
    {
        trace("expression > expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype != $3->dtype) {
            yyerror("> without same dtype");
        }
        d->dtype = _BOOL;
        if ($1->dtype == _INT) {
            if ($1->ival > $3->ival) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else if ($1->dtype == _BOOL) {
            if ($1->bval > $3->bval) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else {
            yyerror("> with wrong dtype");
        }
        $$ = d;
        layers.push(++last_index);
        os << getT() << "isub" << endl;
        os << getT() << "ifgt L_" << layers.top() << endl;
        os << getT() << "iconst_0" << endl;
        os << getT() << "goto L_" << layers.top() << "_end" << endl;
        os << "L_" << layers.top() << ":" << endl;
        os << getT() << "iconst_1" << endl;
        os << "L_" << layers.top() << "_end:" << endl;
        layers.pop();
    }
    | expression '<' expression
    {
        trace("expression < expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype != $3->dtype) {
            yyerror("< without same dtype");
        }
        d->dtype = _BOOL;
        if ($1->dtype == _INT) {
            if ($1->ival < $3->ival) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else if ($1->dtype == _BOOL) {
            if ($1->bval < $3->bval) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else {
            yyerror("< with wrong dtype");
        }
        $$ = d;
        layers.push(++last_index);
        os << getT() << "isub" << endl;
        os << getT() << "iflt L_" << layers.top() << endl;
        os << getT() << "iconst_0" << endl;
        os << getT() << "goto L_" << layers.top() << "_end" << endl;
        os << "L_" << layers.top() << ":" << endl;
        os << getT() << "iconst_1" << endl;
        os << "L_" << layers.top() << "_end:" << endl;
        layers.pop();
    }
    | expression '=' expression
    {
        trace("expression = expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
        SymbolValue *d = new SymbolValue();
        d->dtype = $1->dtype;
        // assign value
        $$ = d;
    }
    | expression GE expression
    {
        trace("expression >= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
        SymbolValue *d = new SymbolValue();
        if ($1->dtype != $3->dtype) {
            yyerror(">= without same dtype");
        }
        d->dtype = _BOOL;
        if ($1->dtype == _INT) {
            if ($1->ival >= $3->ival) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else {
            yyerror(">= with wrong dtype");
        }
        $$ = d;
        layers.push(++last_index);
        os << getT() << "isub" << endl;
        os << getT() << "ifge L_" << layers.top() << endl;
        os << getT() << "iconst_0" << endl;
        os << getT() << "goto L_" << layers.top() << "_end" << endl;
        os << "L_" << layers.top() << ":" << endl;
        os << getT() << "iconst_1" << endl;
        os << "L_" << layers.top() << "_end:" << endl;
        layers.pop();
    }
    | expression LE expression
    {
        trace("expression <= expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
        SymbolValue *d = new SymbolValue();
        if ($1->dtype != $3->dtype) {
            yyerror("<= without same dtype");
        }
        d->dtype = _BOOL;
        if ($1->dtype == _INT) {
            if ($1->ival <= $3->ival) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else {
            yyerror("<= with wrong dtype");
        }
        $$ = d;
        layers.push(++last_index);
        os << getT() << "isub" << endl;
        os << getT() << "ifle L_" << layers.top() << endl;
        os << getT() << "iconst_0" << endl;
        os << getT() << "goto L_" << layers.top() << "_end" << endl;
        os << "L_" << layers.top() << ":" << endl;
        os << getT() << "iconst_1" << endl;
        os << "L_" << layers.top() << "_end:" << endl;
        layers.pop();
    }
    | expression EQ expression
    {
        trace("expression == expression");
        SymbolValue *d = new SymbolValue();
        if ($1->dtype != $3->dtype) {
            yyerror("== without same dtype");
        }
        d->dtype = _BOOL;
        if ($1->dtype == _INT) {
            if ($1->ival == $3->ival) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else if ($1->dtype == _BOOL) {
            if ($1->bval == $3->bval) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else {
            yyerror("== with wrong dtype");
        }
        $$ = d;
        layers.push(++last_index);
        os << getT() << "isub" << endl;
        os << getT() << "ifeq L_" << layers.top() << endl;
        os << getT() << "iconst_0" << endl;
        os << getT() << "goto L_" << layers.top() << "_end" << endl;
        os << "L_" << layers.top() << ":" << endl;
        os << getT() << "iconst_1" << endl;
        os << "L_" << layers.top() << "_end:" << endl;
        layers.pop();
    }
    | expression NE expression
    {
        trace("expression != expression");
        if ($1->dtype != $3->dtype) {
            yyerror("assignment type mismatched");
        }
        SymbolValue *d = new SymbolValue();
        if ($1->dtype != $3->dtype) {
            yyerror("!= without same dtype");
        }
        d->dtype = _BOOL;
        if ($1->dtype == _INT) {
            if ($1->ival != $3->ival) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else if ($1->dtype == _BOOL) {
            if ($1->bval != $3->bval) {
                d->bval = true;
            } else {
                d->bval = false;
            }
        } else {
            yyerror("!= with wrong dtype");
        }
        $$ = d;
        layers.push(++last_index);
        os << getT() << "ifeq L_" << layers.top() << endl;
        os << getT() << "iconst_1" << endl;
        os << getT() << "goto L_" << layers.top() << "_end" << endl;
        os << "L_" << layers.top() << ":" << endl;
        os << getT() << "iconst_0" << endl;
        os << "L_" << layers.top() << "_end:" << endl;
        layers.pop();
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
        if ($2->dtype != _INT) {
            yyerror("- expression not INT");
        }
        os << getT() << "ineg" << endl;
        $$ = new SymbolValue(_INT, _VAR, -($2->ival));
    }
    | expression '&' expression
    {
        trace("expression & expression");
        if ($1->dtype != _BOOL || $3->dtype != _BOOL) {
            yyerror("expression & expression not BOOL");
        }
        os << getT() << "iand" << endl;
        $$ = new SymbolValue(_BOOL, _VAR, $1->bval & $3->bval);
    }
    | expression '|' expression
    {
        trace("expression | expression");
        if ($1->dtype != _BOOL || $3->dtype != _BOOL) {
            yyerror("expression | expression not BOOL");
        }
        os << getT() << "ior" << endl;
        $$ = new SymbolValue(_BOOL, _VAR, $1->bval | $3->bval);
    }
    | '!' expression
    {
        trace("! expression");
        if ($2->dtype != _BOOL) {
            yyerror("! expression not BOOL");
        }
        os << getT() << "ldc 1" << endl;
        os << getT() << "ixor" << endl;
        $$ = new SymbolValue(_BOOL, _VAR, !$2->bval);
    }
    | '+' expression
    {
        trace("+ expression");
        if ($2->dtype != _INT) {
            yyerror("- expression not INT");
        }
        $$ = new SymbolValue(_INT, _VAR, abs($2->ival));
    }
    | '(' expression ')'
    {
        trace("( expression )");
        $$ = $2;
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
        
        $$ = d;
        os << getT() << "invokestatic ";
        if (d->return_dtype == -1) {
            os << "void";
        } else {
            os << toDtypeString(d->return_dtype);
        }
        os << " " << class_name << "." << d->name << "(";
        for (size_t i = 0; i < $3->size(); i++) {
            if (i != 0) {
                os << ", ";
            }
            os << toDtypeString($3->at(i)->dtype);
        }
        os << ")" << endl;
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
    VAR ID
    {
        trace("var decalaration without value and without type");
        SymbolEntry *d;
        d = tables->lookup(*$2, _ALL);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        d = new SymbolEntry(*$2, _VAR);
        insertSymbolEntry(d);
        yyerror("var decalaration without value and without type");
    }
    | VAR ID '=' expression
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
        if (tables->inGlobal()) {
            os << getT() << "field static " << toDtypeString(d->val->dtype) << " " << *$2 << " = ";
            if ($4->dtype == _BOOL) {
                if ($4->bval) {
                    os << "true";
                } else {
                    os << "false";
                }
            } else if ($4->dtype == _INT) {
                os << std::to_string($4->ival);
            }
            os << endl;
        } else {
            d->val->id = stack_number;
            os << getT() << "istore " << stack_number << endl;
            stack_number++;
        }
    }
	| VAR ID ':' type '=' expression
    {
        trace("var decalaration with type");
        SymbolEntry *d;
        d = tables->lookup(*$2, _ALL);
        if (d != NULL) {
            yyerror("duplicate id");
        }
        if ($4 != $6->dtype) {
            yyerror("var decalaration with wrong type");
        }
        d = new SymbolEntry(*$2, _VAR);
        d->val = $6;
        insertSymbolEntry(d);
        if (tables->inGlobal()) {
            os << "\tfield static " << toDtypeString(d->val->dtype) << " " << *$2 << " = ";
            if ($6->dtype == _BOOL) {
                if ($6->bval) {
                    os << "true";
                } else {
                    os << "false";
                }
            } else if ($6->dtype == _INT) {
                os << std::to_string($6->ival);
            }
            os << endl;
        } else {
            d->val->id = stack_number;
            os << getT() << "istore " << stack_number << endl;
            stack_number++;
        }
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
        if (tables->inGlobal()) {
            os << "\tfield static " << toDtypeString(d->val->dtype) << " " << *$2 << endl;
        } else {
            d->val->id = stack_number;
            os << getT() << "sipush 0" << endl;
            os << getT() << "istore " << stack_number << endl;
            stack_number++;
        }
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
        SymbolEntry *d = tables->lookup(*$1, _VAR);
        if (d == NULL) {
            yyerror("undefined id");
        }
        trace($3->dtype);
        if (d->val->dtype != $3->dtype) {
            yyerror("statement assign without same type");
        }
        if (tables->lookup(*$1, _VAR, true)) {
            // global var
            os << getT() << "putstatic " << toDtypeString($3->dtype) << " " << class_name << "." << *$1 << endl;
        } else {
            // local var
            os << getT() << "istore " << std::to_string(d->val->id) << endl;
        }
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
    | PRINT
    {
        os << getT() << "getstatic java.io.PrintStream java.lang.System.out" << endl;
    }
    expression
    {
        trace("statement print");
        os << getT() << "invokevirtual void java.io.PrintStream.print(";
        os << toDtypeString($3->dtype) << ")" << endl;
    }
    | PRINTLN
    {
        os << getT() << "getstatic java.io.PrintStream java.lang.System.out" << endl;
    }
    expression
    {
        trace("statement println");
        os << getT() << "invokevirtual void java.io.PrintStream.println(";
        os << toDtypeString($3->dtype) << ")" << endl;
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
        os << getT() << "ireturn" << endl;
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
        d->return_dtype = -1;
        insertSymbolEntry(d);
        // function parameters
        d->formal_parameters = $4;
        string return_type = "void";

        // reset stack number
        stack_number = 0;

        // TODO
        os << getT() << "method public static " << return_type << " " << *$2 << "(";
        if (*$2 == "main" && $4->size() == 0) {
            os << "java.lang.String[]";
        } else {
            for (size_t i = 0; i < $4->size(); i++) {
                if (i != 0) {
                    os << ", ";
                }
                os << toDtypeString($4->at(i)->val->dtype);
            }
        }
        os << ")" << endl;
        os << getT() << "max_stack 15" << endl << getT() << "max_locals 15" << endl;
        os << getT() << "{" << endl;

        // push
        tables->pushTable();
        for (size_t i = 0; i < $4->size(); i++) {
            insertSymbolEntry($4->at(i));
        }
    }
    function_body
    {
        // dump and pop
        os << getT() << "return" << endl;
        tables->dump();
        tables->popTable();
        SymbolEntry *d = tables->lookup(*$2, _FUN);
        if (d == NULL) {
            yyerror("wrong function closing");
        }
        os << getT() << "}" << endl;
        stack_number = 0;
    }
    | FUN ID '(' function_parameters ')' ':' type
    {
        trace("declare function with return type: " + *$2);
        SymbolEntry *d = new SymbolEntry(*$2, _FUN);
        insertSymbolEntry(d);
        // function paramters
        d->formal_parameters = $4;

        // reset stack number
        stack_number = 0;

        os << getT() << "method public static " << toDtypeString($7) << " " << *$2 << "(";
        if (*$2 == "main" && $4->size() == 0) {
            os << "java.lang.String[]";
        } else {
            for (size_t i = 0; i < $4->size(); i++) {
                if (i != 0) {
                    os << ", ";
                }
                os << toDtypeString($4->at(i)->val->dtype);
            }
        }
        os << ")" << endl;
        os << getT() << "max_stack 15" << endl << getT() << "max_locals 15" << endl;
        os << getT() << "{" << endl;

        // push
        tables->pushTable();
        for (size_t i = 0; i < $4->size(); i++) {
            insertSymbolEntry($4->at(i));
        }
    }
    function_body
    {
        // dump and pop
        tables->dump();
        tables->popTable();
        os << getT() << "}" << endl;
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
        d->type = _VAR;
        d->val = new SymbolValue;
        d->val->dtype = $3;
        d->val->id = stack_number++;
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
    IF expression
    {
        // check if the expression if boolean expression
        if (!($2->dtype == _BOOL)) {
            yyerror("condition without bool expression");
        }
        layers.push(++last_index);
        // os << getT() << "iconst_0" << endl;
        os << getT() << "ifeq L_" << std::to_string(layers.top()) << "_false" << endl;
    }
    condition_body
    {
        os << getT() << "goto L_" << std::to_string(layers.top()) << "_end" << endl;
        trace("condition if else");
    }
    condition_else
    ;

condition_else:
    ELSE
    {
        os << "L_" << std::to_string(layers.top()) << "_false:" << endl;
    }
    condition_body
    {
        os << "L_" << std::to_string(layers.top()) << "_end:" << endl;
        // os << getT() << "nop" << endl;
        layers.pop();
    }
    |
    {
        os << "L_" << std::to_string(layers.top()) << "_false:" << endl;
        // os << getT() << "nop" << endl;
        layers.pop();
    }
    ;

condition_body:
    '{'
    statements
    '}'
    | statement
    ;

// loop
loop:
    WHILE
    {
        layers.push(++last_index);
        os << "L_" << layers.top() << "_begin:" << endl;
    } '(' expression ')'
    {
        trace("loop while");
        if ($4->dtype != _BOOL) {
            yyerror("while loop wrong type");
        }
        os << getT() << "ifeq L_" << layers.top() << "_end" << endl;
        tables->pushTable();
    }
    '{'
    statements
    '}'
    {
        tables->dump();
        tables->popTable();
        // goto beginning of the loop
        os << getT() << "goto L_" << layers.top() << "_begin" << endl;
        // end entry of loop
        os << "L_" << layers.top() << "_end:" << endl;
        os << getT() << "nop" << endl;
        layers.pop();
    }
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

string getT() {
    string res = "";
    for (size_t i = 0; i < tables->tables.size(); i++) {
        res += "\t";
    }
    return res;
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

    string filename(argv[1]);
    size_t dot_pos = filename.find_last_of(".");
    os.open(filename.substr(0, dot_pos) + ".jasm");
    if (!os.is_open()) {
        yyerror("can not open jasm for generating");
        exit(1);
    }
    
    /* perform parsing */
    if (yyparse() == 1)
        yyerror("Parsing error !");
    else
        cout << "Parsed succeed!" << endl;
    
    os.close();
}
