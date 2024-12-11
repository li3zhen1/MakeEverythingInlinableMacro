import MakeEverythingInlinable

@usableFromInline
@MakeEverythingInlinable
struct Foo {
    private var foo: Int
    
    var bar: Int
    
    public var baz: Int {
        bar + 1
    }
}

