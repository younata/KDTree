public protocol KDElement {
    var x: Double { get }
    var y: Double { get }
    var z: Double { get }
}

private let DIMENSIONS_SUPPORTED = 3

public struct KDTree<Element: KDElement> {
    var rootNode: KDNode<Element>?

    public init(collection: [Element]) {
        self.rootNode = nil
        for value in collection {
            self.insert(value: value)
        }
    }

    public init() {
        self.rootNode = nil
    }

    public mutating func insert(value: Element) {
        if self.rootNode == nil {
            self.rootNode = KDNode(value: value)
        } else {
            self.rootNode?.insert(value: value, dimension: 1)
        }
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

    fileprivate func insert(value: Element, dimension: Int) {
        if self.value.effectivelyEquals(value) {
            return // do nothing
        } else if value.get(dimension: dimension) < self.value.get(dimension: dimension) {
            if self.left != nil {
                self.left?.insert(value: value, dimension: (dimension + 1) % DIMENSIONS_SUPPORTED)
            } else {
                self.left = KDNode(value: value)
            }
        } else {
            if self.right != nil {
                self.right?.insert(value: value, dimension: (dimension + 1) % DIMENSIONS_SUPPORTED)
            } else {
                self.right = KDNode(value: value)
            }
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

    // Quick way to estimate distance to the other element (it's only off
    func estimateDistance(to otherElement: Self) -> Double {
        return pow(self.x - otherElement.x, 2) + pow(self.y - otherElement.y, 2) + pow(self.z - otherElement.z, 2)
    }
}
