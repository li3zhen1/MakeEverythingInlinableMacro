# MakeEverythingInlinableMacro


```swift
@usableFromInline
@MakeEverythingInlinable 
struct Foo {
    private var foo: Int
    var bar: Int
    public var baz: Int {
        bar + 1
    }
}
```

⬇️

```swift
@usableFromInline

struct Foo {
    private var foo: Int
    @usableFromInline
    var bar: Int
    @inlinable
    public var baz: Int {
        bar + 1
    }
}
```
