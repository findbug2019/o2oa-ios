//
//  O2DesktopAPI.swift
//  o2app
//
//  Created by 刘振兴 on 2017/12/29.
//  Copyright © 2017年 zone. All rights reserved.
//

import Foundation
import Moya


// MARK:- 所有调用的API枚举
enum O2DesktopAPI {
    case todoItemDetail(String)
    case todoedItemDetail(String)
    case bbsItemDetail(String)
    case cmsItemDetail(String)
    case appItemDetail(String)
    case webConfig
}

// MARK:- 上下文实现
extension O2DesktopAPI:OOAPIContextCapable {
    var apiContextKey: String {
        return "x_desktop"
    }
}


// MARK: - 是否需要加入x-token访问头
extension O2DesktopAPI:OOAccessTokenAuthorizable {
    public var shouldAuthorize: Bool {
        return true
    }
}

extension O2DesktopAPI:TargetType {
    var baseURL: URL {
        let model = O2AuthSDK.shared.centerServerInfo()?.webServer
        let baseURLString = "\(model?.httpProtocol ?? "http")://\(model?.host ?? ""):\(model?.port ?? 80)/\(apiContextKey)"
        if let trueUrl = O2AuthSDK.shared.bindUnitTransferUrl2Mapping(url: baseURLString) {
            return URL(string: trueUrl)!
        }
        return URL(string: baseURLString)!
    }
    
    var path: String {
        switch self {
        case .todoItemDetail(let workid):
            return "/workmobilewithaction.html?workid=\(workid)&\(String.randomString(length: 6))"
        case .todoedItemDetail(let workCompletedId):
            return "/workmobilewithaction.html?workcompletedid=\(workCompletedId)&\(String.randomString(length: 6))"
        case .bbsItemDetail(let subjectId):
            return "/forumdocMobile.html?id=\(subjectId)&\(String.randomString(length: 6))"
        case .cmsItemDetail(let documentId):
            return "/cmsdocMobile.html?id=\(documentId)&\(String.randomString(length: 6))"
        case .appItemDetail(let status):
            return "/appMobile.html?app=portal.Portal&status=\(status)&\(String.randomString(length: 6))"
        case .webConfig:
            return "/res/config/config.json"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var sampleData: Data {
        return "".data(using: String.Encoding.utf8)!
    }
    
    var task: Task {
        return .requestPlain
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    func getCompleteURL() -> URL {
        return  URL(string:baseURL.absoluteString+path)!
    }
    
    
}
