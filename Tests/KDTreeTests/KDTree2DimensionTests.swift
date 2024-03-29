import XCTest
@testable import KDTree

final class KDTree2DimensionTests: XCTestCase {
    // MARK: - Initialization
    func testInitializingFromArray() throws {
        let elements: [TestElement] = [
            TestElement(x: 1, y: 9),
            TestElement(x: 3, y: 6),
            TestElement(x: 0, y: 3),
            TestElement(x: 5, y: 1),

            TestElement(x: 2, y: 2),
            TestElement(x: 8, y: 5),
            TestElement(x: 4, y: 8),
            TestElement(x: 6, y: 4)
        ]

        let tree = try KDTree(collection: elements)

        func assertNoChildren<T: KDElement>(node: KDNode<T>?, line: UInt = #line) {
            XCTAssertNotNil(node, line: line)
            XCTAssertNil(node?.left, line: line)
            XCTAssertNil(node?.right, line: line)
        }

        // Center: (4, 8, 7)
        XCTAssertEqual(tree.rootNode?.value, TestElement(x: 4, y: 8))


        /* Left:
            - (3, 6)
            - (1, 9)
            - (2, 2)
            - (0, 3)
         */

        XCTAssertEqual(tree.rootNode?.left?.value, TestElement(x: 3, y: 6))
        XCTAssertEqual(tree.rootNode?.left?.right?.value, TestElement(x: 1, y: 9))
        assertNoChildren(node: tree.rootNode?.left?.right)

        XCTAssertEqual(tree.rootNode?.left?.left?.value, TestElement(x: 2, y: 2))
        XCTAssertNil(tree.rootNode?.left?.left?.right)
        XCTAssertEqual(tree.rootNode?.left?.left?.left?.value, TestElement(x: 0, y: 3))
        assertNoChildren(node: tree.rootNode?.left?.left?.left)

        /* Right:
            - (5, 1)
            - (6, 4)
            - (8, 5)
         */

        XCTAssertEqual(tree.rootNode?.right?.value, TestElement(x: 6, y: 4))

        XCTAssertEqual(tree.rootNode?.right?.left?.value, TestElement(x: 5, y: 1))
        XCTAssertEqual(tree.rootNode?.right?.right?.value, TestElement(x: 8, y: 5))
        assertNoChildren(node: tree.rootNode?.right?.left)
        assertNoChildren(node: tree.rootNode?.right?.right)
    }

    func testInitializingFromArrayAsync() async throws {
        let elements: [TestElement] = [
            TestElement(x: 1, y: 9),
            TestElement(x: 3, y: 6),
            TestElement(x: 0, y: 3),
            TestElement(x: 5, y: 1),

            TestElement(x: 2, y: 2),
            TestElement(x: 8, y: 5),
            TestElement(x: 4, y: 8),
            TestElement(x: 6, y: 4)
        ]

        let tree = try await KDTree(collection: elements)

        func assertNoChildren<T: KDElement>(node: KDNode<T>?, line: UInt = #line) {
            XCTAssertNotNil(node, line: line)
            XCTAssertNil(node?.left, line: line)
            XCTAssertNil(node?.right, line: line)
        }

        // Center: (4, 8, 7)
        XCTAssertEqual(tree.rootNode?.value, TestElement(x: 4, y: 8))


        /* Left:
            - (3, 6)
            - (1, 9)
            - (2, 2)
            - (0, 3)
         */

        XCTAssertEqual(tree.rootNode?.left?.value, TestElement(x: 3, y: 6))
        XCTAssertEqual(tree.rootNode?.left?.right?.value, TestElement(x: 1, y: 9))
        assertNoChildren(node: tree.rootNode?.left?.right)

        XCTAssertEqual(tree.rootNode?.left?.left?.value, TestElement(x: 2, y: 2))
        XCTAssertNil(tree.rootNode?.left?.left?.right)
        XCTAssertEqual(tree.rootNode?.left?.left?.left?.value, TestElement(x: 0, y: 3))
        assertNoChildren(node: tree.rootNode?.left?.left?.left)

        /* Right:
            - (5, 1)
            - (6, 4)
            - (8, 5)
         */

        XCTAssertEqual(tree.rootNode?.right?.value, TestElement(x: 6, y: 4))

        XCTAssertEqual(tree.rootNode?.right?.left?.value, TestElement(x: 5, y: 1))
        XCTAssertEqual(tree.rootNode?.right?.right?.value, TestElement(x: 8, y: 5))
        assertNoChildren(node: tree.rootNode?.right?.left)
        assertNoChildren(node: tree.rootNode?.right?.right)
    }

    // MARK: - Nearest Neighbor
    private func assertNearestNeighbor(tree: KDTree<TestElement>, searchElement: TestElement, expected: TestElement, line: UInt = #line) {
        guard let nearestNeighbor: TestElement = tree.nearestNeighbor(to: searchElement) else {
            XCTFail("Unable to calculate nearest neighbor: received nil.", line: line)
            return
        }
        if nearestNeighbor != expected {
            let receivedDistance = sqrt(nearestNeighbor.distance(to: searchElement))
            let expectedDistance = sqrt(expected.distance(to: searchElement))
            if abs(receivedDistance - expectedDistance) > 1e-6 { // elements are not equidistant.
                XCTFail("\(nearestNeighbor) is not closest element to \(searchElement). Expected \(expected). Expected is \(expectedDistance) units away and received is \(receivedDistance) units away.", line: line)
            }
        }
    }

    func testFindNearestNeighbor() throws {
        let elements: [TestElement] = [
            TestElement(x: 4, y: 10),
            TestElement(x: 3, y: 11),
            TestElement(x: 2, y: 12),
            TestElement(x: 5, y: 13),

            TestElement(x: 8, y: 4),
            TestElement(x: 1, y: 5),
            TestElement(x: 6, y: 7),
            TestElement(x: 3, y: 9)
        ]

        let tree = try KDTree(collection: elements)

        // Exact match/Element actually exists in the tree
        assertNearestNeighbor(tree: tree, searchElement: TestElement(x: 8, y: 4), expected: TestElement(x: 8, y: 4))

        // Searched for element doesn't exist, finds the closest to it.
        assertNearestNeighbor(tree: tree, searchElement: TestElement(x: 2.5, y: 11.5), expected: TestElement(x: 2, y: 12))
    }

    func testNearestNeighborFuzzTest() throws {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<2000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        for _ in 0..<100 {
            let searchingElement = TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )

            let nearestNeighborNaiveSolution = elements.min {
                $0.distance(to: searchingElement) < $1.distance(to: searchingElement)
            }!

            let tree = try KDTree(collection: elements)
            assertNearestNeighbor(tree: tree, searchElement: searchingElement, expected: nearestNeighborNaiveSolution)
        }
    }

    func testPerformanceInitialization() throws {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<50_000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        self.measure {
            _ = try! KDTree(collection: elements)
        }
    }

    func testPerformanceAsyncInitializion() async throws {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<50_000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        await self.measureAsync {
            _ = try! await KDTree(collection: elements)
        }
    }

    func measureAsync(tries: Int = 10, testName: String = #function, line: Int = #line, _ action: () async -> Void) async {
        var durations: [TimeInterval] = []
        for _ in 0..<tries {
            let start = Date()
            await action()
            durations.append(Date().timeIntervalSince(start))
        }
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let message = """
        \(testName): measured: Average duration \(averageDuration) seconds.
        """
        NSLog(message)
//        record(XCTIssue(type: .performanceRegression, compactDescription: message, sourceCodeContext: XCTSourceCodeContext(location: XCTSourceCodeLocation(filePath: #file, lineNumber: line))))
    }

    func testPerformanceNearestNeighbor() throws {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<200000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        let tree = try KDTree(collection: elements)
        self.measure {
            _ = tree.nearestNeighbor(to: TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            ))
        }
    }

    func testNearestNeighborVsNaive() throws {
        let maxValue: Double = 200
        var generator = SystemRandomNumberGenerator()
        let elements: [TestElement] = (0..<20000).map { _ in
            return TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            )
        }

        let tree = try KDTree(collection: elements)

        var treeTimes: [TimeInterval] = []
        for _ in 0..<100 {
            let start = Date()
            _ = tree.nearestNeighbor(to: TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
            ))
            let end = Date()
            treeTimes.append(end.timeIntervalSince(start))
        }

        var naiveTimes: [TimeInterval] = []
        for _ in 0..<100 {
            let start = Date()
            let searchingElement = TestElement(
                x: generator.nextDouble(upperBound: maxValue) - (maxValue / 2),
                y: generator.nextDouble(upperBound: maxValue) - (maxValue / 2)
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

    // MARK: - Nearest Neighbors
    func testNearest_returnsAllNodesWithinRadiusOfElement() throws {
        let elements: [TestElement] = [
            TestElement(x: 4, y: 10), // ~7.2
            TestElement(x: 3, y: 11), // ~8.6
            TestElement(x: 2, y: 12), // 10
            TestElement(x: 5, y: 13), // ~9.5

            TestElement(x: 8, y: 4), // 0
            TestElement(x: 1, y: 5), // ~7.1
            TestElement(x: 6, y: 7), // ~3.6
            TestElement(x: 3, y: 9), // ~7.1
        ]

        let tree = try KDTree(collection: elements)

        XCTAssertEqual(tree.nearest(to: TestElement(x: 8, y: 4), within: 5), [
            TestElement(x: 8, y: 4),
            TestElement(x: 6, y: 7),
        ])
    }

    static var allTests = [
        ("testInitializingFromArray", testInitializingFromArray),
        ("testInitializingFromArrayAsync", testInitializingFromArrayAsync),
        ("testFindNearestNeighbor", testFindNearestNeighbor),
        ("testNearestNeighborFuzzTest", testNearestNeighborFuzzTest),
        ("testPerformanceInitialization", testPerformanceInitialization),
        ("testPerformanceAsyncInitializion", testPerformanceAsyncInitializion),
        ("testPerformanceNearestNeighbor", testPerformanceNearestNeighbor),
        ("testNearestNeighborVsNaive", testNearestNeighborVsNaive),
        ("testNearest_returnsAllNodesWithinRadiusOfElement", testNearest_returnsAllNodesWithinRadiusOfElement),
    ]
}
