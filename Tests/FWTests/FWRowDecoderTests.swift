import XCTest
@testable import FW

final class FWRowDecoderTests: XCTestCase {
    func testDecodePartialRow1() throws {
        struct FWRow: Decodable, Equatable {
            let a: Int
            let b: Int
            let c: Int
        }

        let fw = "abc\n123\n---"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [1, 1, 1], hasHeaderRow: true, allowPartialRow: true)
        let decoder = FWRowDecoder()

        while reader.next() != nil {
            guard let row = try? decoder.decode(FWRow.self, from: reader) else {
                XCTAssertEqual(reader.currentRow, ["-", "-", "-"])
                break
            }
            XCTAssertEqual(row, FWRow(a: 1, b: 2, c: 3))
        }
    }

    func testDecodePartialRow2() throws {
        struct FWRow: Decodable, Equatable {
            let a: Int?
            let b: Int?
            let c: Int?
        }

        let fw = "abc\n123\n "

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [1, 1, 1], hasHeaderRow: true, allowPartialRow: true)
        let decoder = FWRowDecoder()

        var records = [FWRow]()
        while reader.next() != nil {
            guard let row = try? decoder.decode(FWRow.self, from: reader) else {
                XCTFail("could not decode \(String(describing: reader.currentRow))")
                return
            }
            records.append(row)
        }

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0], FWRow(a: 1, b: 2, c: 3))
        XCTAssertEqual(records[1], FWRow(a: nil, b: nil, c: nil))
    }

    func testDecodePartialRow3() throws {
        struct FWRow: Decodable, Equatable {
            let a: Int?
            let b: Int?
            let c: Int?
        }

        let fw = "abc\n123\n"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [1, 1, 1], hasHeaderRow: true, allowPartialRow: true)
        let decoder = FWRowDecoder()

        var records = [FWRow]()
        while reader.next() != nil {
            guard let row = try? decoder.decode(FWRow.self, from: reader) else {
                XCTFail("could not decode \(String(describing: reader.currentRow))")
                return
            }
            records.append(row)
        }

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0], FWRow(a: 1, b: 2, c: 3))
    }

    func testDecodeCustomNilDecoding() throws {
        struct FWRow: Decodable, Equatable {
            let a: Int?
            let b: Int?
            let c: Int?
        }

        let fw = "abc\n123\n---\n"

        let reader = try! FWReader(string: fw, rowWidth: 4, fieldSizes: [1, 1, 1], hasHeaderRow: true, allowPartialRow: true)
        let decoder = FWRowDecoder()
        decoder.nilDecodingStrategy = .custom { $0 == "-" }

        var records = [FWRow]()
        while reader.next() != nil {
            guard let row = try? decoder.decode(FWRow.self, from: reader) else {
                XCTFail("could not decode \(String(describing: reader.currentRow))")
                return
            }
            records.append(row)
        }

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0], FWRow(a: 1, b: 2, c: 3))
        XCTAssertEqual(records[1], FWRow(a: nil, b: nil, c: nil))
    }
}
