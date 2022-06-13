## Modified sections from project 2
* condition reduce rules for goto
* fixed a few project 2 errors
* added lots for java byte code generator
* `stack<int> layers` for branching and loop
* `int stack_number` for stack counter
* `getT()` for better looking in .jasm
* fixed global and local variables rules from projec 2
* rewrote procedure decalartions to prevent conflicts

## Compile and Run
```shell
make clean
make
./compiler <filename>.kt
./javaa/javaa <filename>.jasm
./java <filename>.java
```
