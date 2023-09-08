import Foundation

enum UnicodeBOM {
    static let utf8: [UInt8] = [0xef, 0xbb, 0xbf]
    static let utf16BE: [UInt8] = [0xfe, 0xff]
    static let utf16LE: [UInt8] = [0xff, 0xfe]
    static let utf32BE: [UInt8] = [0x00, 0x00, 0xfe, 0xff]
    static let utf32LE: [UInt8] = [0xff, 0xfe, 0x00, 0x00]
}

extension UnicodeBOM {
    fileprivate static func readBOM(buffer: UnsafePointer<UInt8>, count: Int) -> (Endian, Int)? {
        if count >= 4 {
            if compare(buffer: buffer, bom: UnicodeBOM.utf32BE) {
                return (.big, UnicodeBOM.utf32BE.count)
            }
            if compare(buffer: buffer, bom: UnicodeBOM.utf32LE) {
                return (.little, UnicodeBOM.utf32LE.count)
            }
        }
        if count >= 3 {
            if compare(buffer: buffer, bom: UnicodeBOM.utf8) {
                return (.unknown, UnicodeBOM.utf8.count)
            }
        }
        if count >= 2 {
            if compare(buffer: buffer, bom: UnicodeBOM.utf16BE) {
                return (.big, UnicodeBOM.utf16BE.count)
            }
            if compare(buffer: buffer, bom: UnicodeBOM.utf16LE) {
                return (.little, UnicodeBOM.utf16LE.count)
            }
        }
        return nil
    }

    private static func compare(buffer: UnsafePointer<UInt8>, bom: [UInt8]) -> Bool {
        for i in 0 ..< bom.count {
            guard buffer[i] == bom[i] else {
                return false
            }
        }
        return true
    }
}

internal class BinaryReader {
    private let stream: InputStream
    private let endian: Endian

    private let _buffer: UnsafeMutablePointer<UInt8>
    private let _capacity: Int
    private var _count: Int = 0
    private var _position: Int = 0

    internal init(
        stream: InputStream,
        endian: Endian,
        bufferSize: Int = Int(UInt16.max)) throws {

        var endian = endian

        if stream.streamStatus == .notOpen {
            stream.open()
        }
        if stream.streamStatus != .open {
            throw FWError.cannotOpenFile
        }

        _buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        _capacity = bufferSize
        _count = stream.read(_buffer, maxLength: _capacity)
        if _count < 0 {
            throw FWError.cannotReadFile
        }

        var position = 0
        if let (e, l) = UnicodeBOM.readBOM(buffer: _buffer, count: _count) {
            if endian != .unknown && endian != e {
                throw FWError.stringEndianMismatch
            }
            endian = e
            position = l
        }
        _position = position

        self.stream = stream
        self.endian = endian
    }

    deinit {
        if stream.streamStatus != .closed {
            stream.close()
        }
        _buffer.deallocate()
    }

    internal var hasBytesAvailable: Bool {
        if _count - _position > 0 {
            return true
        }
        return stream.hasBytesAvailable
    }

    @inline(__always)
    private func readStream(_ buffer: UnsafeMutablePointer<UInt8>, maxLength: Int) throws -> Int {
        var count = 0
        for i in 0 ..< maxLength {
            if _position >= _count {
                let result = stream.read(_buffer, maxLength: _capacity)
                if result < 0 {
                    if let error = stream.streamError {
                        throw FWError.streamErrorHasOccurred(error: error)
                    } else {
                        throw FWError.cannotReadFile
                    }
                }
                _count = result
                _position = 0
                if result == 0 {
                    break
                }
            }
            buffer[i] = _buffer[_position]
            _position += 1
            count += 1
        }
        return count
    }

    internal func readUInt8() throws -> UInt8 {
        let bufferSize = 1
        var buffer: UInt8 = 0
        if try readStream(&buffer, maxLength: bufferSize) != bufferSize {
            throw FWError.cannotReadFile
        }
        return buffer
    }

    internal func readUInt16() throws -> UInt16 {
        let bufferSize = 2
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        if try readStream(buffer, maxLength: bufferSize) != bufferSize {
            throw FWError.stringEncodingMismatch
        }
        return try buffer.withMemoryRebound(to: UInt16.self, capacity: 1) {
            switch endian {
            case .big:
                return UInt16(bigEndian: $0.pointee)
            case .little:
                return UInt16(littleEndian: $0.pointee)
            default:
                throw FWError.stringEndianMismatch
            }
        }
    }

    internal func readUInt32() throws -> UInt32 {
        let bufferSize = 4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        if try readStream(buffer, maxLength: bufferSize) != bufferSize {
            throw FWError.stringEncodingMismatch
        }
        return try buffer.withMemoryRebound(to: UInt32.self, capacity: 1) {
            switch endian {
            case .big:
                return UInt32(bigEndian: $0.pointee)
            case .little:
                return UInt32(littleEndian: $0.pointee)
            default:
                throw FWError.stringEndianMismatch
            }
        }
    }
}

extension BinaryReader {
    internal class UInt8Iterator: Sequence, IteratorProtocol {
        private let reader: BinaryReader

        fileprivate init(reader: BinaryReader) {
            self.reader = reader
        }

        internal func next() -> UInt8? {
            if !reader.hasBytesAvailable {
                return nil
            }
            do {
                return try reader.readUInt8()
            } catch {
                return nil
            }
        }

    }

    internal func makeUInt8Iterator() -> UInt8Iterator {
        return UInt8Iterator(reader: self)
    }
}

extension BinaryReader {
    internal class UInt16Iterator: Sequence, IteratorProtocol {
        private let reader: BinaryReader

        fileprivate init(reader: BinaryReader) {
            self.reader = reader
        }

        internal func next() -> UInt16? {
            if !reader.hasBytesAvailable {
                return nil
            }
            do {
                return try reader.readUInt16()
            } catch {
                return nil
            }
        }

    }

    internal func makeUInt16Iterator() -> UInt16Iterator {
        return UInt16Iterator(reader: self)
    }
}

extension BinaryReader {
    internal class UInt32Iterator: Sequence, IteratorProtocol {
        private let reader: BinaryReader

        fileprivate init(reader: BinaryReader) {
            self.reader = reader
        }

        internal func next() -> UInt32? {
            if !reader.hasBytesAvailable {
                return nil
            }
            do {
                return try reader.readUInt32()
            } catch {
                return nil
            }
        }
    }

    internal func makeUInt32Iterator() -> UInt32Iterator {
        return UInt32Iterator(reader: self)
    }
}
