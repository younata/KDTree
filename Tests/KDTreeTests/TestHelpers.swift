import XCTest
@testable import KDTree

struct TestElement: KDElement, Equatable, CustomStringConvertible {
    let values: [Double]

    init(x: Double, y: Double) {
        self.values = [x, y]
    }

    init(x: Double, y: Double, z: Double) {
        self.values = [x, y, z]
    }

    func distance(to other: TestElement) -> Double {
        return sqrt(zip(self.values, other.values).reduce(0) { $0 + pow($1.0 - $1.1, 2) })
    }

    var description: String {
        return self.values.map { String($0) }.joined(separator: ", ")
    }
}

extension RandomNumberGenerator {
    @inlinable public mutating func nextDouble(upperBound: Double) -> Double {
        return Double(self.next(upperBound: UInt(upperBound * 256))) / 256
    }
}

extension Array where Element == Double {
    func mean() -> Double {
        guard self.isEmpty == false else { return .nan }
        return self.reduce(0, +) / Double(self.count)
    }
}
