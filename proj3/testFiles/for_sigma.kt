class ForSigma
{
  // constants and variables
  val n = 10
  var sum: int
  var index: int

  fun main () {
    sum = 0
    index = 0
    
    for (index in 0..n) {
      sum = sum + index
    }
    print ("The sum is ")
    println (sum)
  }
}