//
//  O2UserDefaults.swift
//  O2OA_SDK_Framwork
//
//  Created by FancyLou on 2018/11/7.
//

import Foundation
import SwiftyUserDefaults


// MARK: - 扩展自定义对象存储
extension UserDefaults {
    subscript(key: DefaultsKey<O2BindUnitModel?>) -> O2BindUnitModel? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<O2CenterServerModel?>) -> O2CenterServerModel? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<O2LoginAccountModel?>) -> O2LoginAccountModel? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    
    subscript(key: DefaultsKey<O2CustomStyleModel?>) -> O2CustomStyleModel? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<O2BindDeviceModel?>) -> O2BindDeviceModel? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<IMConfig?>) -> IMConfig? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
    subscript(key: DefaultsKey<OOMeetingConfigInfo?>) -> OOMeetingConfigInfo? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }

}
// MARK:- 扩展定义的键
extension DefaultsKeys {
    static let unit = DefaultsKey<O2BindUnitModel?>("O2unit")
    static let device = DefaultsKey<O2BindDeviceModel?>("O2device")
    static let deviceToken = DefaultsKey<String?>("deviceToken")
    static let apnsToken = DefaultsKey<String?>("apnsToken")
    static let pushType = DefaultsKey<String?>("pushType")
    static let centerServer = DefaultsKey<O2CenterServerModel?>("O2centerServer")
    static let myInfo = DefaultsKey<O2LoginAccountModel?>("O2myInfo")
    static let customStyle = DefaultsKey<O2CustomStyleModel?>("O2customStyle")
    static let customStyleHash = DefaultsKey<String?>("O2customStyleHash")
    static let searchHistory = DefaultsKey<[String]?>("O2SearchHistoryKey")
    static let imConfig = DefaultsKey<IMConfig?>("imConfig")
    static let meetingConfig = DefaultsKey<OOMeetingConfigInfo?>("meetingConfig")
}

class O2UserDefaults {
    
    static let shared: O2UserDefaults = {
        return O2UserDefaults()
    }()
    
    private init() {}
    
    var myInfo: O2LoginAccountModel? {
        get {
            guard let me = Defaults[.myInfo] else {
                return nil
            }
            return me
        }
        set {
            Defaults[.myInfo] = newValue
        }
    }
    var unit: O2BindUnitModel? {
        get {
            guard let unit = Defaults[.unit] else {
                return nil
            }
            return unit
        }
        set {
            Defaults[.unit] =  newValue
        }
    }
    var device: O2BindDeviceModel? {
        get {
            guard let device = Defaults[.device] else {
                return nil
            }
            return device
        }
        set {
            Defaults[.device] = newValue
        }
    }
    var deviceToken: String? {
        get {
            guard let token = Defaults[.deviceToken] else {
                return "deviceToken0x0x000000000xxxxxxxxxxxx"
            }
            return token
        }
        set {
            Defaults[.deviceToken] = newValue
            if let device = Defaults[.device]  {
                device.name = newValue
                Defaults[.device] = device
            }
        }
    }
    var pushType: String? {
        get {
            guard let token = Defaults[.pushType] else {
                return ""
            }
            return token
        }
        set {
            Defaults[.pushType] = newValue
        }
    }
    var apnsToken: String? {
        get {
            guard let token = Defaults[.apnsToken] else {
                return ""
            }
            return token
        }
        set {
            Defaults[.apnsToken] = newValue
        }
    }
    var centerServer: O2CenterServerModel? {
        get {
            guard let server = Defaults[.centerServer] else {
                return nil
            }
            return server
        }
        set {
            Defaults[.centerServer] =  newValue
        }
    }
    var customStyle: O2CustomStyleModel? {
        get {
            guard let style = Defaults[.customStyle] else {
                return nil
            }
            return style
        }
        set {
            Defaults[.customStyle] = newValue
        }
    }
    var customStyleHash: String? {
        get {
            guard let hash = Defaults[.customStyleHash] else {
                return ""
            }
            return hash
        }
        set {
            Defaults[.customStyleHash] = newValue
        }
    }
    
    var searchHistory: [String] {
        get {
            guard let history = Defaults[.searchHistory] else {
                return []
            }
            return history
        }
        set {
            Defaults[.searchHistory] = newValue
        }
    }
    
    var imConfig: IMConfig? {
        get {
            guard let config = Defaults[.imConfig] else {
                return IMConfig()
            }
            return config
        }
        set {
            Defaults[.imConfig] = newValue
        }
    }
    
    var meetingConfig: OOMeetingConfigInfo? {
        get {
            guard let config = Defaults[.meetingConfig] else {
                return OOMeetingConfigInfo()
            }
            return config
        }
        set {
            Defaults[.meetingConfig] = newValue
        }
    }
    
}
