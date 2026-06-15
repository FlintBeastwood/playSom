import Testing
import Foundation
@testable import playSom

@Suite("SomaFMService — parsing and validation")
struct SomaFMServiceParsingTests {

    private func writeTempPLS(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("playSomTest-\(UUID().uuidString).pls")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func parsesFile1Entry() async throws {
        let url = try writeTempPLS("""
        [playlist]
        numberofentries=1
        File1=https://ice2.somafm.com/groovesalad-128-aac
        Title1=Groove Salad
        Length1=-1
        Version=2
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = SomaFMService()
        let result = try await service.parsePlaylistURL(url)
        #expect(result.absoluteString == "https://ice2.somafm.com/groovesalad-128-aac")
    }

    @Test func upgradesHTTPToHTTPS() async throws {
        let url = try writeTempPLS("""
        [playlist]
        File1=http://ice2.somafm.com/groovesalad-128-aac
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = SomaFMService()
        let result = try await service.parsePlaylistURL(url)
        #expect(result.scheme == "https")
    }

    @Test func rejectsUntrustedDomain() async throws {
        let url = try writeTempPLS("""
        [playlist]
        File1=https://evil.example.com/stream
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = SomaFMService()
        await #expect(throws: SomaFMService.SomaFMError.self) {
            _ = try await service.parsePlaylistURL(url)
        }
    }

    @Test func acceptsSubdomainOfSomaFM() async throws {
        let url = try writeTempPLS("""
        [playlist]
        File1=https://ice2.somafm.com/groovesalad-128-aac
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = SomaFMService()
        let result = try await service.parsePlaylistURL(url)
        #expect(result.host == "ice2.somafm.com")
    }

    @Test func throwsWhenNoFileEntryPresent() async throws {
        let url = try writeTempPLS("""
        [playlist]
        Version=2
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = SomaFMService()
        await #expect(throws: SomaFMService.SomaFMError.noStreamURLFound) {
            _ = try await service.parsePlaylistURL(url)
        }
    }

    @Test func parsesLowercaseFileKey() async throws {
        let url = try writeTempPLS("""
        [playlist]
        file1=https://ice2.somafm.com/groovesalad-128-aac
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = SomaFMService()
        let result = try await service.parsePlaylistURL(url)
        #expect(result.absoluteString == "https://ice2.somafm.com/groovesalad-128-aac")
    }

    @Test func fallbackChannelsListIsNonEmpty() {
        #expect(SomaFMService.fallbackChannels.isEmpty == false)
        #expect(SomaFMService.fallbackChannels.contains(where: { $0.id == "groovesalad" }))
    }
}
