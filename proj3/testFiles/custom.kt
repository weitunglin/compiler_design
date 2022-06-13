/* Sigma.kt
 *
 * Compute sum = 1 + 2 + ... + n
 */

class Sigma
{
  // constants and variables
  val n = 10
  var sum: int
  var index: int

  fun main () {
    sum = 0
    index = 0
    val r = 5
    
    while (index <= n) {
      sum = sum + index
      index = index + 1
    }
    print ("The sum is ")
    println (sum)
  }

  val q = 5
  var a

  // function declaration
  fun add (a: int, b: int) : int {
    return a+b
  }

  fun t() {
    if (true)
      print ("not valid")
    else
      print ("else")
    
    var c = add(n, 10)
    if (c > 10)
      print -c
    else
      print c
  }
}