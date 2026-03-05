import Foundation
import SwiftData

@Model
final class TreasureChest {
    var id: UUID
    var integrity: Int
    var tier: Int

    static let maxChestsPerGame = 3

    init(integrity: Int, tier: Int) {
        precondition(tier >= 1 && tier <= 3, "Chest tier must be 1, 2, or 3")
        self.id = UUID()
        self.integrity = integrity
        self.tier = tier
    }

    var isDestroyed: Bool {
        integrity <= 0
    }

    func takeDamage(_ amount: Int) -> Int {
        let actual = min(amount, integrity)
        integrity -= actual
        return actual
    }
}
