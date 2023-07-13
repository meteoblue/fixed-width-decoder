import Foundation

public class FWReader {
    let rowWidth: Int
    let hasHeaderRow: Bool
    let allowPartialRow: Bool
    let trimFields: Bool

    var iterator: String.UnicodeScalarView.Iterator

    private let startIndices: [Int]
    private let endIndices: [Int]

    public fileprivate (set) var headerRow: [String]?
    public fileprivate (set) var currentRow: [String]?

    public init(string: String, rowWidth: Int, fieldSizes: [Int], hasHeaderRow: Bool = false, allowPartialRow: Bool = false, trimFields: Bool = false) throws {
        self.rowWidth = rowWidth
        self.hasHeaderRow = hasHeaderRow
        self.allowPartialRow = allowPartialRow
        self.trimFields = trimFields

        startIndices = fieldSizes.reduce(into: [0], { acc, e in acc.append(acc.last! + e) }).dropLast()
        endIndices = fieldSizes.reduce(into: [], { acc, e in acc.append((acc.last ?? 0) + e) })

        self.iterator = string.unicodeScalars.makeIterator()

        if hasHeaderRow {
            headerRow = try next()
            currentRow = nil
        } else {
            headerRow = nil
            currentRow = nil
        }
    }

    @discardableResult
    public func next() -> [String]? {
        let rawRow = readRow()

        guard
            let row = rawRow,
            !row.isEmpty
        else {
            currentRow = nil
            return nil
        }

        var result = [String](repeating: "", count: startIndices.count)

        for (index, (start, end)) in zip(startIndices, endIndices).enumerated() {
            if start > row.count {
                break
            }

            let startIndex = row.index(row.startIndex, offsetBy: start)
            let endIndex = row.index(row.startIndex, offsetBy: min(end, row.count))

            let value = String(row[startIndex..<endIndex])

            result[index] = trimFields ? value.trimmingCharacters(in: .whitespacesAndNewlines) : value
        }

        currentRow = result
        return result
    }

    private func readRow() -> String? {
        var result = [Unicode.Scalar?](repeating: nil, count: rowWidth)
        var index = 0
        while index < rowWidth, let character = iterator.next() {
            result[index] = character
            index += 1
        }

        if index == rowWidth {
            return String(result.map { Character($0!) })
        } else if allowPartialRow {
            return String(result[..<index].map { Character($0!) })
        } else {
            return nil
        }
    }
}
