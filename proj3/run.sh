#! /bin/sh
./compiler testFiles/$1.kt
./javaa/javaa testFiles/$1.jasm
