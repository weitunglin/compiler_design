#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <iostream>
#include <string>
#include <stack>
#include <vector>
#include <map>

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

using std::cout;
using std::endl;
using std::string;
using std::stack;
using std::vector;
using std::map;

const int _INT = 0;
const int _FLOAT = 1;
const int _BOOL = 2;
const int _STRING = 3;

const int _ALL = -1;
const int _VAL = 0;
const int _VAR = 1;
const int _ARRAY = 2;
const int _FUN = 3;
const int _CLASS = 4;

string toTypeString(int t) {
    if (t == 0) {
        return "VAL";
    } else if (t == 1) {
        return "VAR";
    } else if (t == 2) {
        return "ARRAY";
    } else if (t == 3) {
        return "FUN";
    } else if (t == 4) {
        return "CLASS";
    }
    return "";
}

class SymbolValue {
public:
    int ival;
    bool bval;
    float fval;
    char cval;
    string *sval;

    int dtype;
    int type;

    SymbolValue() {}
    SymbolValue(int d, int t, int v) : dtype(d), type(t), ival(v) {}
    SymbolValue(int d, int t, bool v) : dtype(d), type(t), bval(v) {}
    SymbolValue(int d, int t, float v) : dtype(d), type(t), fval(v) {}
    SymbolValue(int d, int t, string *v) : dtype(d), type(t), sval(v) {}
};

class SymbolEntry {
public:
    string name;
    int type;

    SymbolValue *val;

    int size;
    vector<SymbolValue*> *arr;

    int return_dtype;
    vector<SymbolEntry*> *formal_parameters;

    SymbolEntry() {}
    SymbolEntry(string s, int t) : name(s), type(t) {}
};

class SymbolTable {
public:
    map<string, SymbolEntry*> table;

    bool insert(SymbolEntry* entry) {
        if (table.find(entry->name) == table.end()) {
            table[entry->name] = entry;
            return true;
        }
        return false;
    }

    SymbolEntry* lookup(string name, int type) {
        auto result = table.find(name);
        if (result == table.end()) {
            return NULL;
        }
        if (type == -1 || result->second->type == type) {
            return result->second;
        }
        return NULL;
    }

    void dump() {
        for (const auto &i : table) {
            cout
                << "name: " << i.first << "\t"
                << "type: " << toTypeString(i.second->type)
                << endl;
        }
    }
};

class SymbolTables {
public:
    stack<SymbolTable*> tables;

    SymbolTables() {
        pushTable();
    }

    void pushTable() {
        tables.push(new SymbolTable());
    }

    void popTable() {
        tables.pop();
    }

    void dump() {
        cout << endl;
        cout << "Dumping Symbol Table" << endl;
        cout << "Start Table" << endl;
        tables.top()->dump();
        cout << "End Table" << endl;
        cout << endl;
    }

    bool insert(SymbolEntry* entry) {
        if (tables.size()) {
            return tables.top()->insert(entry);
        } else {
            return false;
        }
    }

    SymbolEntry* lookup(string name, int type) {
        vector<SymbolTable*> t;
        SymbolEntry* result = NULL;
        while (!tables.empty()) {
            auto top = tables.top();
            result = top->lookup(name, type);
            if (result != NULL) {
                while (!t.empty()) {
                    tables.push(t.back());
                    t.pop_back();
                }
                return result;
            }
            t.push_back(top);
            tables.pop();
        }
        while (!t.empty()) {
            tables.push(t.back());
            t.pop_back();
        }
        return NULL;
    }
};
#endif
