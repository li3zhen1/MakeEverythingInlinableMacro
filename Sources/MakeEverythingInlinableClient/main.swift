import MakeEverythingInlinable

@usableFromInline
@MakeEverythingInlinable
struct Foo {
    private var foo: Int
    
    @MakeEverythingInlinable
    struct S {
        var bar: Int
    }
    
    var bar: Int
    
    public var baz: Int {
        bar + 1
    }
}

