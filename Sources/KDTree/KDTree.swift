public protocol KDElement {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
}

private let DIMENSIONS_SUPPORTED = 3

public struct KDTree<Element: KDElement> {
    var rootNode: KDNode<Element>?

    public init(collection: [Element]) {
        self.rootNode = KDNode(elements: collection, dimension: 0, totalDimensions: DIMENSIONS_SUPPORTED)
    }

    public func smallestElement(dimension: Int) -> Element? {
        guard let rootNode = self.rootNode else { return nil }
        return rootNode.smallestElement(dimension: dimension, treeDimension: 0)
    }

    public func nearestNeighbor(to element: Element, within radius: Double) -> Element? {
        guard let rootNode = self.rootNode else { return nil }

        return rootNode.nearestNeighbor(
            to: element,
            currentDimension: 0,
            radius: pow(radius, 2), // we aren't sqrt'ing distances in this search.
            closestElement: rootNode.value,
            closestDistance: Double.infinity
        ).0
    }
}

class KDNode<Element: KDElement> {
    let value: Element
    var left: KDNode<Element>?
    var right: KDNode<Element>?

    init(value: Element) {
        self.value = value
        self.left = nil
        self.right = nil
    }

    init?(elements: [Element], dimension: Int, totalDimensions: Int) {
        guard elements.isEmpty == false else { return nil }
        let sortedElements = elements.sorted { $0.get(dimension: dimension) < $1.get(dimension: dimension) }

        let medianIndex = sortedElements.count / 2
        self.value = sortedElements[medianIndex]

        let nextDimension = (dimension + 1) % totalDimensions

        if medianIndex > 0 {
            self.left = KDNode(elements: Array(sortedElements[0..<medianIndex]), dimension: nextDimension, totalDimensions: totalDimensions)
        } else {
            self.left = nil
        }
        if (medianIndex + 1) < sortedElements.count {
            self.right = KDNode(elements: Array(sortedElements[(medianIndex+1)..<sortedElements.count]), dimension: nextDimension, totalDimensions: totalDimensions)
        } else {
            self.right = nil
        }
    }

    fileprivate func smallestElement(dimension: Int, treeDimension: Int) -> Element {
        if treeDimension == dimension {
            guard let left = self.left else { return self.value }
            return left.smallestElement(dimension: dimension, treeDimension: (treeDimension + 1) % DIMENSIONS_SUPPORTED)
        } else {
            return [
                self.left?.smallestElement(dimension: dimension, treeDimension: (treeDimension + 1) % DIMENSIONS_SUPPORTED),
                self.right?.smallestElement(dimension: dimension, treeDimension: (treeDimension + 1) % DIMENSIONS_SUPPORTED),
                self.value
                ].compactMap { $0 }.min { $0.get(dimension: dimension) < $1.get(dimension: dimension) } ?? self.value
        }
    }

    fileprivate func nearestNeighbor(to element: Element, currentDimension: Int, radius: Double, closestElement: Element, closestDistance: Double) -> (Element, Double) {
        guard closestDistance > radius else { return (closestElement, closestDistance) }

        var bestGuess = closestElement
        var bestDistance = closestDistance

        let currentDistance = element.estimateDistance(to: self.value)
        if currentDistance < bestDistance {
            bestGuess = self.value
            bestDistance = currentDistance
        }

        let nextDimension = (currentDimension + 1) % DIMENSIONS_SUPPORTED
        if element.get(dimension: currentDimension) < self.value.get(dimension: currentDimension) {
            if let left = self.left {
                (bestGuess, bestDistance) = left.nearestNeighbor(to: element, currentDimension: nextDimension, radius: radius, closestElement: bestGuess, closestDistance: bestDistance)
            }
            if let right = self.right {
                (bestGuess, bestDistance) = right.nearestNeighbor(to: element, currentDimension: nextDimension, radius: radius, closestElement: bestGuess, closestDistance: bestDistance)
            }
        } else {
            if let right = self.right {
                (bestGuess, bestDistance) = right.nearestNeighbor(to: element, currentDimension: nextDimension, radius: radius, closestElement: bestGuess, closestDistance: bestDistance)
            }
            if let left = self.left {
                (bestGuess, bestDistance) = left.nearestNeighbor(to: element, currentDimension: nextDimension, radius: radius, closestElement: bestGuess, closestDistance: bestDistance)
            }
        }
        return (bestGuess, bestDistance)
    }
}

import Foundation

private extension KDElement {
    func get(dimension: Int) -> Double {
        switch (dimension % DIMENSIONS_SUPPORTED) {
        case 0: return self.x
        case 1: return self.y
        default: return self.z
        }
    }

    func effectivelyEquals(_ otherElement: Self) -> Bool {
        guard abs(self.x - otherElement.x) < 1e-6 else { return false }
        guard abs(self.y - otherElement.y) < 1e-6 else { return false }
        return abs(self.z - otherElement.z) < 1e-6
    }

    // Quick way to estimate distance to the other element, for comparing two elements only.
    func estimateDistance(to otherElement: Self) -> Double {
        let x = self.x - otherElement.x
        let y = self.y - otherElement.y
        let z = self.z - otherElement.z
        return (x * x) + (y * y) + (z * z)
        // Apparently, (a * a) is just faster than using pow(a, 2).
        // See KDTreeTests.testPerformancePow2VsNaiveSquaring for example.
    }
}
