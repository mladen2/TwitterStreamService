//
//  NetworkService.swift
//  Twitrack
//
//  Created by Mladen Nisevic on 10/08/2021.
//

import Foundation

public protocol NetworkDelegate {
    func newData(_ data: Data)
    func showError(_ error: Error)
    func showMessage(_ message: String)
    func networkDisconnected()
}

public class NetworkService: NSObject {

    let baseURL = "https://stream.twitter.com/1.1/statuses/filter.json"

    var decoder: JSONDecoder
    var session: URLSession?

    var httpMethod: HTTPMethod = .POST
    var currentTask: URLSessionDataTask?

    public var delegate: NetworkDelegate?
    public var termsToSearch: [String] = []

    var theSearchTerms: String = ""

    public var isStreaming: Bool {
        currentTask != nil && currentTask!.state == URLSessionTask.State.running
    }

    //
    public var consumerKey: String?
    public var consumerSecret: String?
    public var token: String?
    public var tokenSecret: String?

    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
        super.init()
        let conf = URLSessionConfiguration.default
        //        conf.waitsForConnectivity = true
        self.session = URLSession(configuration: conf, delegate: self, delegateQueue: .current)
    }

    public func startStreaming(completion: (Result<Bool, Error>) -> Void) {

        // track
        theSearchTerms = paramTermsString(termsToSearch)
        let query = baseURL + URLRequestConstants.startParams + trackTerms(theSearchTerms)

        // location
//        var arr2 = [String]()
//        let locs = [-122.75,36.8,-121.75,37.8] // san fran.
//        // [long, lat]
////        let locs = [13.218791,43.48012,21.225747,45.753836] // zag -> Sa
//        // lon
////        let locs = [-0.206077,51.474422,-0.075958,51.537462] // lon
//        for loc in locs {
//            arr2.append("\(loc)")
//        }
//
//
//        theSearchTerms = paramTermsString(arr2)
//        let query = baseURL + URLRequestConstants.startParams + locations()

        // follow
//        theSearchTerms = "elonmusk"
//        let query = baseURL + URLRequestConstants.startParams + trackTerms(theSearchTerms)

        guard let url = URL(string: query) else {
            completion(.failure(LocalError.badURL(url: query)))
            return
        }

        guard let request = buildRequest(url) else { return }
        currentTask?.cancel()
        currentTask = session?.dataTask(with: request)
        currentTask?.resume()
        completion(.success(true))
    }

    public func stop() {
        currentTask?.cancel()
    }
}

// MARK: -
// MARK: Request helper methods
// MARK: -
extension NetworkService {

    func buildRequest(_ url: URL) -> URLRequest? {

        guard let consumerKey = consumerKey,
              let consumerSecret = consumerSecret,
              let token = token,
              let tokenSecret = tokenSecret else {
            return nil
        }

        var tw = TwitterAuthSignature(
            oauthConsumerKey: consumerKey,
            oauthConsumerSecret: consumerSecret,
            oauthNonce: UUID().uuidString,
            oauthSignatureMethod: URLRequestConstants.method,
            oauthTimestamp: "\(Int(Date().timeIntervalSince1970))",
            oauthToken: token,
            oauthTokenSecret: tokenSecret,
            oauthVersion: URLRequestConstants.version,
            otherParams: [StreamParamName.track: theSearchTerms]
//            otherParams: [StreamParamName.follow: theSearchTerms]
//            otherParams: [StreamParamName.locations: theSearchTerms]
        )

        let sig = HttpSignature(method: httpMethod, baseURL: baseURL, twitterAuthSigParams: tw)
        tw.oauthSignature = sig.sha1HmacSig()
        let userAuthString = Authorization.getAuthorizationString(tw.authorizationParams())

        var request = URLRequest(url: url)
        request.setValue(userAuthString, forHTTPHeaderField: POSTHeaderKey.authorization)

        request.httpMethod = httpMethod.rawValue
//        request.setValue(POSTHeaderValue.appJson, forHTTPHeaderField: POSTHeaderKey.contentType)
        request.setValue(POSTHeaderValue.appXForm, forHTTPHeaderField: POSTHeaderKey.contentType)
        return request
    }

    func trackTerms(_ searchParamsString: String) -> String {
        StreamParamName.track + URLRequestConstants.paramDelimiter + searchParamsString
    }

    func follow(_ searchParamsString: String) -> String {
        StreamParamName.follow + URLRequestConstants.paramDelimiter + searchParamsString
    }

    func locations() -> String {
        StreamParamName.locations + URLRequestConstants.paramDelimiter + theSearchTerms
    }

    func paramTermsString(_ terms: [String]) -> String {
        guard !terms.isEmpty else { return "" }
        var str = ""
        for term in terms {
            str += term
            if term != terms.last {
                str += ","
            }
        }
        return str
    }
}

// MARK: -
// MARK: URL Session Delegate
// MARK: -
extension NetworkService: URLSessionDelegate, URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        delegate?.newData(data)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let error = error ?? LocalError.urlSessionCompletedWithError
        print("error: \(error.localizedDescription)")
        delegate?.showError(error)
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        let error = error ?? LocalError.urlSessionBecameInvalid
        print("error: \(error.localizedDescription)")
        delegate?.showError(error)
    }
}
