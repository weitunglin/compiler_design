class returnScopeTest {
    fun foo() : int {
        val a = 1
        {
            return a
        }
    }

    fun main() {
        foo()
    }
}