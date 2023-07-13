# fixed-width-decoder

fixed width string reading library written in Swift.

## Usage for reading fixed width strings

### From string

```swift
import FW

let fwString = "  1foo\n  2bar\n"
let reader = try! FWReader(string: fwString, rowWidth: 7, fieldSizes: [3, 3])
while let row = reader.next() {
    print("\(row)")
}
// => ["  1", "foo"]
// => ["  2", "bar"]
```
