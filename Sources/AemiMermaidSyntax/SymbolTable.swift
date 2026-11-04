internal import AemiInterner

/// The ids of a diagram as dense numbers: `symbol(_:)` interns the bytes of an id, and a ``SlotMap`` says what each number names.
struct SymbolTable {
    private let interner = Interner()

    /// The number of the id `bytes`, new if it has not been seen.
    func symbol(_ bytes: ArraySlice<UInt8>) -> Int {
        Int(bytes.withUnsafeBytes { unsafe interner.intern($0) }.rawValue)
    }
}

/// What each symbol names, or -1: an array that grows to the symbol asked for.
struct SlotMap {
    private var named: [Int32] = []

    func get(_ symbol: Int) -> Int32 { symbol < named.count ? named[symbol] : -1 }

    mutating func set(_ symbol: Int, _ value: Int32) {
        while named.count <= symbol { named.append(-1) }
        named[symbol] = value
    }
}
