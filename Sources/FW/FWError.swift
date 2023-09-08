public enum FWError: Error {
    case cannotOpenFile
    case cannotReadFile
    case streamErrorHasOccurred(error: Error)
    case stringEncodingMismatch
    case stringEndianMismatch
    case partialRow
}
