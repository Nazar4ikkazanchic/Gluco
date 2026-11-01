import Foundation

struct TelegramError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct TelegramChat: Identifiable, Hashable {
    let id: String
    let title: String
}

struct TelegramClient {
    let token: String

    private struct Response<T: Decodable>: Decodable {
        let ok: Bool
        let description: String?
        let result: T?
    }

    private struct Update: Decodable {
        struct Message: Decodable {
            struct Chat: Decodable {
                let id: Int64
                let title: String?
                let first_name: String?
                let last_name: String?
                let username: String?
            }
            let chat: Chat
        }
        let message: Message?
    }

    private struct Empty: Decodable {}

    private func endpoint(_ method: String) throws -> URL {
        let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let url = URL(string: "https://api.telegram.org/bot\(t)/\(method)") else {
            throw TelegramError(message: "Не вказано токен Telegram-бота")
        }
        return url
    }

    func send(chatID: String, text: String) async throws {
        var request = URLRequest(url: try endpoint("sendMessage"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["chat_id": chatID, "text": text])
        let (data, _) = try await URLSession.shared.data(for: request)
        let r = try JSONDecoder().decode(Response<Empty>.self, from: data)
        if !r.ok { throw TelegramError(message: r.description ?? "Telegram не прийняв повідомлення") }
    }

    /// Chats that recently wrote to the bot (ask parents to send /start first).
    func recentChats() async throws -> [TelegramChat] {
        let (data, _) = try await URLSession.shared.data(from: try endpoint("getUpdates"))
        let r = try JSONDecoder().decode(Response<[Update]>.self, from: data)
        if !r.ok { throw TelegramError(message: r.description ?? "Помилка Telegram") }
        var seen = Set<String>()
        var chats: [TelegramChat] = []
        for u in (r.result ?? []).reversed() {
            guard let c = u.message?.chat else { continue }
            let id = String(c.id)
            if seen.contains(id) { continue }
            seen.insert(id)
            let name = c.title ?? [c.first_name, c.last_name].compactMap { $0 }.joined(separator: " ")
            chats.append(TelegramChat(id: id, title: name.isEmpty ? (c.username ?? id) : name))
        }
        return chats
    }
}
