public protocol KDElement {
    var values: [Double] { get }
}

public enum KDTreeError: Error {
    case dimensionsDiffer
}

public struct KDTree<Element: KDElement> {
    var rootNode: KDNode<Element>?

    public init(collection: [Element]) throws {
        guard let supportedDimensions = collection.first?.values.count,
            collection.allSatisfy({ $0.values.count == supportedDimensions }) else {
                throw KDTreeError.dimensionsDiffer
        }
        self.rootNode = KDNode(elements: collection, dimension: 0, totalDimensions: supportedDimensions)
    }

    public func nearestNeighbor(to element: Element) -> Element? {
        guard var best = self.rootNode else { return nil }

        var stack: [(KDNode<Element>, Int)] = [(best, 0)]
        var closest = best.value.estimateDistance(to: element)

        while stack.isEmpty == false {
            guard let (branch, dimension) = stack.popLast() else {
                continue
            }

            let currentDistance = branch.value.estimateDistance(to: element)
            let currentDistanceDimension = branch.value.get(dimension: dimension) - element.get(dimension: dimension)


            if (currentDistance <= closest) {
                closest = currentDistance
                best = branch
            }

            let nextDimension = (dimension + 1) % branch.value.values.count

            let section: KDNode<Element>?
            let other: KDNode<Element>?

            if (currentDistanceDimension > 0) {
                section = branch.left
                other = branch.right
            } else {
                section = branch.right
                other = branch.left
            }

            if let section = section {
                stack.append((section, nextDimension))
            }
            if let other = other, (currentDistanceDimension * currentDistanceDimension) < closest {
                stack.append((other, nextDimension))
            }
        }

        return best.value
    }

    public func nearest(to element: Element, within radius: Double) -> [Element] {
        let maxDistance = radius * radius
        var closest: [Element] = []
        guard let rootBranch = self.rootNode else { return closest }

        var stack: [(KDNode<Element>, Int)] = [(rootBranch, 0)]

        while stack.isEmpty == false {
            guard let (branch, dimension) = stack.popLast() else {
                continue
            }

            let currentDistance = branch.value.estimateDistance(to: element)

            if currentDistance <= maxDistance {
                closest.append(branch.value)
            }

            let currentDistanceDimension = branch.value.get(dimension: dimension) - element.get(dimension: dimension)

            let section: KDNode<Element>?
            let other: KDNode<Element>?

            if (currentDistanceDimension > 0) {
                section = branch.left
                other = branch.right
            } else {
                section = branch.right
                other = branch.left
            }

            let nextDimension = (dimension + 1) % branch.value.values.count

            if let section = section {
                stack.append((section, nextDimension))
            }
            if let other = other, (currentDistanceDimension * currentDistanceDimension) < maxDistance {
                stack.append((other, nextDimension))
            }
        }

        return closest.sorted {
            element.estimateDistance(to: $0) < element.estimateDistance(to: $1)
        }
    }
}

class KDNode<Element: KDElement> {
    let value: Element
    var left: KDNode<Element>?
    var right: KDNode<Element>?

    private var totalDimensions: Int { self.value.values.count }

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
}

import Foundation

private extension KDElement {
    func get(dimension: Int) -> Double {
        return self.values[dimension % self.values.count]
    }

    func effectivelyEquals(_ otherElement: Self) -> Bool {
        return zip(self.values, otherElement.values).allSatisfy { abs($0 - $1) < 1e-6 }
    }

    // Quick way to estimate distance to the other element, for comparing two elements only.
    func estimateDistance(to otherElement: Self) -> Double {
        return zip(self.values, otherElement.values).reduce(0) {
            let difference = ($1.0 - $1.1)
            return $0 + (difference * difference)
        }
        // Apparently, (a * a) is just faster than using pow(a, 2).
        // See KDTreeTests.testPerformancePow2VsNaiveSquaring for example.
    }
}
