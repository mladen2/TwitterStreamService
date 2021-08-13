//
//  File.swift
//  
//
//  Created by Mladen Nisevic on 13/08/2021.
//

import Foundation

enum HTTPMethod: String {
    case GET
    case POST
}

struct POSTHeaderValue {
    static let appJson = "application/json; charset=utf-8"
    static let appXForm = "application/x-www-form-urlencoded"
}

struct POSTHeaderKey {
    static let authorization = "Authorization"
    static let contentType = "Content-Type"
    static let accept = "Accept"
    static let close = "Close"
}


struct StreamParamName {
    static let track = "track"
    static let follow = "follow"
    static let locations = "locations"
}
