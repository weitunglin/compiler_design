/* Sigma.kt
 *
 * Compute sum = 1 + 2 + ... + n
 */

class Sigma
{
  // constants and variables
  val n = 10
  var sum: int = 0
  var index: int

  var q = 5

  fun main () {
    sum = 0
    index = 0
    var r = 5
    
    while (index <= n) {
      sum = sum + index
      index = index + 1
    }
    print ("The sum is ")
    println (sum)
  }

  // function declaration
  fun add (a: int, b: int) : int {
    return a+b
  }

  fun sub (c: int, d: int) : int {
    return c - d
  }

  fun t(x: int, y: float, z: bool) {
    if (true) {
      print ("valid1")
      if (true) {
        print ("valid2")
      } else {
        print ("valid3")
        
      }
      print("a")
    }
    else
      print ("else")

    if (true) { 
      print("ab")
    }
    
    var c = add(n, 10)
    if (c > 10)
      print -c
    else
      print c
  }
}