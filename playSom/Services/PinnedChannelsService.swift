import Foundation

/// Persists pinned channel IDs to UserDefaults.
@MainActor
final class PinnedChannelsService: ObservableObject {

    private static let storageKey = "com.playSom.pinnedChannels"

    @Published private(set) var pinnedIds: Set<String> = []
    private var pinned: [PinnedChannel] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Public API

    func isPinned(id: String) -> Bool {
        pinnedIds.contains(id)
    }

    func pin(id: String) {
        guard !pinnedIds.contains(id) else { return }
        pinned.append(PinnedChannel(id: id, pinnedAt: Date()))
        pinnedIds.insert(id)
        save()
    }

    func unpin(id: String) {
        guard pinnedIds.contains(id) else { return }
        pinned.removeAll { $0.id == id }
        pinnedIds.remove(id)
        save()
    }

    @discardableResult
    func togglePin(id: String) -> Bool {
        if pinnedIds.contains(id) {
            unpin(id: id)
            return false
        } else {
            pin(id: id)
            return true
        }
    }

    func clearAll() {
        pinned.removeAll()
        pinnedIds.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(pinned)
            defaults.set(data, forKey: Self.storageKey)
        } catch {
            print("[PinnedChannelsService] save failed: \(error)")
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey) else { return }
        do {
            pinned = try JSONDecoder().decode([PinnedChannel].self, from: data)
            pinnedIds = Set(pinned.map { $0.id })
        } catch {
            print("[PinnedChannelsService] load failed: \(error)")
        }
    }
}
