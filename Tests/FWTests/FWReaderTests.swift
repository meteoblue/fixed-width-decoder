import XCTest
@testable import FW

final class FWReaderTests: XCTestCase {
    func testReadPartialRow1() throws {
        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [3], hasHeaderRow: true, allowPartialRow: true)

        XCTAssertEqual(reader.headerRow, ["abc"])
        XCTAssertEqual(reader.next(), ["123"])
        XCTAssertEqual(reader.currentRow, ["123"])
        XCTAssertEqual(reader.next(), ["---"])
        XCTAssertEqual(reader.currentRow, ["---"])
        XCTAssertEqual(reader.next(), nil)
        XCTAssertEqual(reader.currentRow, nil)
    }

    func testReadPartialRow2() throws {
        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [4], hasHeaderRow: true, allowPartialRow: true)

        XCTAssertEqual(reader.headerRow, ["abc\n"])
        XCTAssertEqual(reader.next(), ["123\n"])
        XCTAssertEqual(reader.currentRow, ["123\n"])
        XCTAssertEqual(reader.next(), ["---"])
        XCTAssertEqual(reader.currentRow, ["---"])
        XCTAssertEqual(reader.next(), nil)
        XCTAssertEqual(reader.currentRow, nil)
    }

    func testIterate() throws {
        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [4], hasHeaderRow: true, allowPartialRow: true)

        var count = 0
        while reader.next() != nil {
            count += 1
        }

        XCTAssertEqual(count, 2)
    }

    func testReadPartialMultiColumn1() throws {
        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [1, 1, 1], hasHeaderRow: true, allowPartialRow: true)

        XCTAssertEqual(reader.headerRow, ["a", "b", "c"])
        XCTAssertEqual(reader.next(), ["1", "2", "3"])
        XCTAssertEqual(reader.currentRow, ["1", "2", "3"])
        XCTAssertEqual(reader.next(), ["-", "-", "-"])
        XCTAssertEqual(reader.currentRow, ["-", "-", "-"])
        XCTAssertEqual(reader.next(), nil)
        XCTAssertEqual(reader.currentRow, nil)
    }

    func testReadPartialMultiColumn2() throws {
        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [1, 1, 1, 1], hasHeaderRow: true, allowPartialRow: true)

        XCTAssertEqual(reader.headerRow, ["a", "b", "c", "\n"])
        XCTAssertEqual(reader.next(), ["1", "2", "3", "\n"])
        XCTAssertEqual(reader.currentRow, ["1", "2", "3", "\n"])
        XCTAssertEqual(reader.next(), ["-", "-", "-", ""])
        XCTAssertEqual(reader.currentRow, ["-", "-", "-", ""])
        XCTAssertEqual(reader.next(), nil)
        XCTAssertEqual(reader.currentRow, nil)
    }

    func testReadPartialMultiColumn3() throws {
        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [2, 2], hasHeaderRow: true, allowPartialRow: true)

        XCTAssertEqual(reader.headerRow, ["ab", "c\n"])
        XCTAssertEqual(reader.next(), ["12", "3\n"])
        XCTAssertEqual(reader.currentRow, ["12", "3\n"])
        XCTAssertEqual(reader.next(), ["--", "-"])
        XCTAssertEqual(reader.currentRow, ["--", "-"])
        XCTAssertEqual(reader.next(), nil)
        XCTAssertEqual(reader.currentRow, nil)
    }

    func testStream() throws {
        let stream = InputStream(data: "abc\n123\n---".data(using: .utf8)!)

        let reader = try! FWReader(stream: stream, codecType: Unicode.UTF8.self, rowWidth: 4, fieldSizes: [4], hasHeaderRow: true, allowPartialRow: true)

        var count = 0
        while reader.next() != nil {
            count += 1
        }

        XCTAssertEqual(count, 2)
    }
}
