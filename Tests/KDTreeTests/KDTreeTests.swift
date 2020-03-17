import XCTest
@testable import KDTree

final class KDTreeTests: XCTestCase {
    func testInitializingFromArray() {
        let elements: [TestElement] = [
            TestElement(x: 1, y: 9, z: 1),
            TestElement(x: 3, y: 6, z: 2),
            TestElement(x: 0, y: 3, z: 3),
            TestElement(x: 5, y: 1, z: 4),

            TestElement(x: 2, y: 2, z: 5),
            TestElement(x: 8, y: 5, z: 6),
            TestElement(x: 4, y: 8, z: 7),
            TestElement(x: 6, y: 4, z: 8)
        ]

        let tree = KDTree(collection: elements)

        func assertNoChildren<T: KDElement>(node: KDNode<T>?, line: UInt = #line) {
            XCTAssertNotNil(node, line: line)
            XCTAssertNil(node?.left, line: line)
            XCTAssertNil(node?.right, line: line)
        }

        // Center: (4, 8, 7)
        XCTAssertEqual(tree.rootNode?.value, TestElement(x: 4, y: 8, z: 7))


        /* Left:
            - (3, 6, 2)
            - (0, 3, 3)
            - (1, 9, 1)
            - (2, 2, 5)
         */

        XCTAssertEqual(tree.rootNode?.left?.value, TestElement(x: 3, y: 6, z: 2))
        XCTAssertEqual(tree.rootNode?.left?.right?.value, TestElement(x: 1, y: 9, z: 1))
        assertNoChildren(node: tree.rootNode?.left?.right)

        XCTAssertEqual(tree.rootNode?.left?.left?.value, TestElement(x: 2, y: 2, z: 5))
        XCTAssertNil(tree.rootNode?.left?.left?.right)
        XCTAssertEqual(tree.rootNode?.left?.left?.left?.value, TestElement(x: 0, y: 3, z: 3))
        assertNoChildren(node: tree.rootNode?.left?.left?.left)

        /* Right:
            - (5, 1, 4)
            - (6, 4, 8)
            - (8, 5, 6)
         */

        XCTAssertEqual(tree.rootNode?.right?.value, TestElement(x: 6, y: 4, z: 8))

        XCTAssertEqual(tree.rootNode?.right?.left?.value, TestElement(x: 5, y: 1, z: 4))
        XCTAssertEqual(tree.rootNode?.right?.right?.value, TestElement(x: 8, y: 5, z: 6))
        assertNoChildren(node: tree.rootNode?.right?.left)
        assertNoChildren(node: tree.rootNode?.right?.right)
    }

    func testFindSmallestValueForADimension() {
        let elements: [TestElement] = [
            TestElement(x: 4, y: 10, z: 0),
            TestElement(x: 3, y: 11, z: 2),
            TestElement(x: 2, y: 12, z: 3),
            TestElement(x: 5, y: 13, z: 4),

            TestElement(x: 8, y: 4, z: 5),
            TestElement(x: 1, y: 5, z: 6),
            TestElement(x: 6, y: 7, z: 7),
            TestElement(x: 3, y: 9, z: 8)
        ]

        let tree = KDTree(collection: elements)

        XCTAssertEqual(tree.smallestElement(dimension: 0), TestElement(x: 1, y: 5, z: 6))
        XCTAssertEqual(tree.smallestElement(dimension: 1), TestElement(x: 8, y: 4, z: 5))
        XCTAssertEqual(tree.smallestElement(dimension: 2), TestElement(x: 4, y: 10, z: 0))
    }

    func testFindClosestValue() {
        let elements: [TestElement] = [
            TestElement(x: 4, y: 10, z: 0),
            TestElement(x: 3, y: 11, z: 2),
            TestElement(x: 2, y: 12, z: 3),
            TestElement(x: 5, y: 13, z: 4),

            TestElement(x: 8, y: 4, z: 5),
            TestElement(x: 1, y: 5, z: 6),
            TestElement(x: 6, y: 7, z: 7),
            TestElement(x: 3, y: 9, z: 8)
        ]

        let tree = KDTree(collection: elements)

        XCTAssertEqual(tree.nearestNeighbor(to: TestElement(x: 8, y: 4, z: 5), within: 2), TestElement(x: 8, y: 4, z: 5)) // Exact match/Element actually exists in the tree

        XCTAssertEqual(tree.nearestNeighbor(to: TestElement(x: 2.5, y: 11.5, z: 4), within: 2), TestElement(x: 2, y: 12, z: 3)) // Searched for element doesn't exist, finds the closest to it.
    }

    func testNearestNeighborFuzzTest() {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<2000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        for _ in 0..<100 {
            let searchingElement = TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )

            let nearestNeighborNaiveSolution = elements.min {
                $0.distance(to: searchingElement) < $1.distance(to: searchingElement)
            }!

            let tree = KDTree(collection: elements)
            XCTAssertEqual(tree.nearestNeighbor(to: searchingElement, within: 1), nearestNeighborNaiveSolution)
        }
    }

    func testPerformanceNearestNeighbor() {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<200000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        let tree = KDTree(collection: elements)
        self.measure {
            _ = tree.nearestNeighbor(to: TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            ), within: 10)
        }
    }

    func testNearestNeighborVsNaive() {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<20000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        let tree = KDTree(collection: elements)

        var treeTimes: [TimeInterval] = []
        for _ in 0..<100 {
            let start = Date()
            _ = tree.nearestNeighbor(to: TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            ), within: 10)
            let end = Date()
            treeTimes.append(end.timeIntervalSince(start))
        }

        var naiveTimes: [TimeInterval] = []
        for _ in 0..<100 {
            let start = Date()
            let searchingElement = TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                z: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )

            _ = elements.min {
                $0.distance(to: searchingElement) < $1.distance(to: searchingElement)
            }!
            let end = Date()
            naiveTimes.append(end.timeIntervalSince(start))
        }

        print("Tree time average: \(treeTimes.mean())")
        print("Naive time average: \(naiveTimes.mean())")
        XCTAssertLessThan(treeTimes.mean(), naiveTimes.mean())
    }

    static var allTests = [
        ("testInitializingFromArray", testInitializingFromArray),
        ("testFindSmallestValueForADimension", testFindSmallestValueForADimension),
        ("testFindClosestValue", testFindClosestValue),
        ("testNearestNeighborFuzzTest", testNearestNeighborFuzzTest),
        ("testPerformanceNearestNeighbor", testPerformanceNearestNeighbor),
        ("testNearestNeighborVsNaive", testNearestNeighborVsNaive),
    ]
}

struct TestElement: KDElement, Equatable {
    let x: Double
    let y: Double
    let z: Double

    func distance(to other: TestElement) -> Double {
        return pow(self.x - other.x, 2) + pow(self.y - other.y, 2) + pow(self.z - other.z, 2)
    }
}

extension RandomNumberGenerator {
    @inlinable public mutating func nextDouble(upperBound: Double) -> Double {
        return Double(self.next(upperBound: UInt(upperBound)))
    }
}

extension Array where Element == Double {
    func mean() -> Double {
        guard self.isEmpty == false else { return .nan }
        return self.reduce(0, +) / Double(self.count)
    }
}
