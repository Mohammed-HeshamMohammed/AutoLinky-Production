import Foundation

public enum JSON: Codable, Sendable, Equatable, Identifiable {
    case object([String: JSON]), array([JSON]), string(String), number(Double), bool(Bool), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode([JSON].self) { self = .array(v) }
        else { self = .object(try c.decode([String: JSON].self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    public subscript(_ key: String) -> JSON { if case .object(let v) = self { return v[key] ?? .null }; return .null }
    public var text: String { if case .string(let v) = self { return v }; return "" }
    public var items: [JSON] { if case .array(let v) = self { return v }; return [] }
    public var strings: [String] { items.compactMap { if case .string(let v) = $0 { return v }; return nil } }
    public var flag: Bool { if case .bool(let v) = self { return v }; return false }
    public var integer: Int { if case .number(let v) = self, v.isFinite, v >= Double(Int.min), v < Double(Int.max) { return Int(v) }; return 0 }
    public var isNull: Bool { self == .null }
    public var id: String { for key in ["slug", "id", "title"] { if !self[key].text.isEmpty { return self[key].text } }; return self["job"]["id"].text }
    public static func strings(_ values: [String]) -> JSON { .array(values.map(JSON.string)) }
}

public struct Job: Identifiable, Sendable, Equatable {
    public let raw: JSON
    public init(_ raw: JSON) { self.raw = raw }
    public var id: String { raw["id"].text }
    public var title: String { raw["title"].text }
    public var company: String { raw["company"].text }
    public var location: String { [raw["city"].text, raw["country"].text].filter { !$0.isEmpty }.joined(separator: ", ") }
    public var methods: [String] { let values = raw["apply_methods"].strings; return values.isEmpty && raw["source"].text == "linkedin_job" ? ["easy_apply", "external"] : values }
    public var application: JSON { raw["application"] }
    public var matchPercent: Int? { raw["match_percent"].isNull ? nil : min(100, max(0, raw["match_percent"].integer)) }
    public var description: String { raw["description"].text.isEmpty ? raw["snippet"].text : raw["description"].text }
    public func destination(for method: String) -> URL? {
        let contacts = raw["contacts"].items
        let value = contacts.first { $0["type"].text == method }?["value"].text ?? ""
        if method == "whatsapp" || method == "phone" {
            let digits = value.filter { $0.isASCII && $0.isNumber }
            guard (8...15).contains(digits.count) else { return nil }
            return URL(string: method == "phone" ? "tel:+\(digits)" : "https://wa.me/\(digits)")
        }
        let fallback = method == "dm" ? raw["author_url"].text : raw["url"].text
        return Security.webURL(value.isEmpty ? fallback : value)
    }
}

public struct JobPage: Sendable {
    public let jobs: [Job]
    public let cursor: String?
    public init(_ raw: JSON) {
        jobs = raw["items"].items.map(Job.init).filter { !$0.id.isEmpty }
        cursor = raw["next_cursor"].text.isEmpty ? nil : raw["next_cursor"].text
    }
}

public enum CVUpload {
    public static let maximumBytes = 4 * 1024 * 1024
    public static func contentType(name: String, bytes: Int) throws -> String {
        guard bytes > 0 else { throw APIError(status: 400, code: "cv_empty") }
        guard bytes <= maximumBytes else { throw APIError(status: 413, code: "cv_too_large") }
        switch (name as NSString).pathExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        default: throw APIError(status: 415, code: "cv_bad_type")
        }
    }
}

public struct APIError: Error, LocalizedError, Sendable, Equatable {
    public let status: Int
    public let code: String
    public let requestID: String?
    public let retryAfter: Int?
    public init(status: Int, code: String, requestID: String? = nil, retryAfter: Int? = nil) { self.status = status; self.code = code; self.requestID = requestID; self.retryAfter = retryAfter }
    public var errorDescription: String? { code }
}
