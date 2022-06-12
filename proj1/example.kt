/*
 * Example with Functions
 */

class example {
  // constants
  val a = 5

  // variables
  var c : int

  // function declaration
  fun add (a: int, b: int) : int {
    return a+b
  }
  
  // main statements
  fun main() {
    c = add(a, 10)
    if (c > 10)
      print -c
    else
      print c
    println ("Hello"" "" World")
  }
}

// a comment // line with { delimiters } before the end

/* this is a comment // line with some /* and 
C delimiters */