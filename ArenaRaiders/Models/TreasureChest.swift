import Foundation

final class TreasureChest {
    var id: UUID
    var integrity: Int
    var tier: Int

    static let maxChestsPerGame = 3

    init(integrity: Int, tier: Int) {
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
