//
//  URLBuilder.swift
//  Helpearth
//
//  Created by 中嶋裕也 on 2021/12/02.
//

import Foundation


class URLBuilder {
    static func getURL() -> String {
        let baseHelpearthURL = "https://helpearth.bubbleapps.io/version-test/view"
        let id = UUID().uuidString
        let url = baseHelpearthURL + "?id=" + id
        return url
    }
}
