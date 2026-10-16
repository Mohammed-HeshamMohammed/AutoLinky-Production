import Foundation

private final class OriginRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard let original = task.originalRequest?.url, let next = request.url,
              original.scheme == next.scheme, original.host == next.host, original.port == next.port else { completionHandler(nil); return }
        completionHandler(request)
    }
}
public enum IsolatedSession {
    public static func make() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil; config.httpCookieStorage = nil; config.httpShouldSetCookies = false
        return URLSession(configuration: config, delegate: OriginRedirectPolicy(), delegateQueue: nil)
    }
}
