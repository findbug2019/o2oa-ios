//
//  AppDelegate.swift
//  O2Platform
//
//  Created by 刘振兴 on 16/6/14.
//  Copyright © 2016年 zoneland. All rights reserved.
//

import UIKit
import CocoaLumberjack
import AlamofireNetworkActivityIndicator
import UserNotifications

//import Flutter
import IQKeyboardManagerSwift








let isProduction = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, JPUSHRegisterDelegate, UNUserNotificationCenterDelegate {
  
    var _mapManager: BMKMapManager?
    var window: UIWindow?
    
    //中心服务器节点类
    public static let o2Collect = O2Collect()
    //网络监听
    public let o2ReachabilityManager = O2ReachabilityManager.sharedInstance
    // flutter engine
//    var flutterEngine : FlutterEngine?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        let themeName = AppConfigSettings.shared.themeName
        if themeName != "" {
            //主题
            print("主题色：\(themeName)")
            O2ThemeManager.setTheme(plistName: themeName, path: .mainBundle)
        }else {
            O2ThemeManager.setTheme(plistName: "red", path: .mainBundle)
        }
        //搜索框
        UISearchBar.appearance().theme_barTintColor = ThemeColorPicker(keyPath: "Base.base_color")
        UISearchBar.appearance().tintColor = UIColor.white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).theme_tintColor = ThemeColorPicker(keyPath: "Base.base_color")
        
    
        //启动日志管理器
        O2Logger.startLogManager()
        //日志文件
//        _ = O2Logger.getLogFiles()
        O2Logger.debug("设置运行版本==========,\(PROJECTMODE)")
        //网络检查
        o2ReachabilityManager.startListening()
        //Alamofire
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        //db
        let _ = DBManager.shared
        
        //设置一个是否第一授权的标志
        if #available(iOS 10.0, *){
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            let options:UNAuthorizationOptions = [.badge,.alert,.sound]
            center.requestAuthorization(options: options, completionHandler: { (granted, err) in
                if granted ==  true {
                    //记录已经打开授权
                    //print("aaaaaaaaaaaa")
                    AppConfigSettings.shared.notificationGranted = true
                    AppConfigSettings.shared.firstGranted = true
                    NotificationCenter.default.post(name: NSNotification.Name.init("SETTING_NOTI"), object: nil)
                }else{
                    //记录禁用授权
                    AppConfigSettings.shared.notificationGranted = false
                    AppConfigSettings.shared.firstGranted = true
                    NotificationCenter.default.post(name: NSNotification.Name.init("SETTING_NOTI"), object: nil)
                }
            })
            
        }else{
            let types:UIUserNotificationType = [.badge,.alert,.sound]
            let setting = UIUserNotificationSettings(types: types, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(setting)
        }
        
 
        //Buglyy异常上报
        Bugly.start(withAppId: BUGLY_ID)
        
        //JPush
        _setupJPUSH()
        JPUSHService.setup(withOption: launchOptions, appKey: JPUSH_APP_KEY, channel: JPUSH_channel, apsForProduction: isProduction)
        
        _mapManager = BMKMapManager()
        BMKMapManager.setCoordinateTypeUsedInBaiduMapSDK(.COORDTYPE_BD09LL)
        _mapManager?.start(BAIDU_MAP_KEY, generalDelegate: nil)
        
        
        JPUSHService.registrationIDCompletionHandler { (resCode, registrationID) in
            if resCode == 0 {
                O2Logger.debug("registrationID获取成功\(registrationID ?? "")")
                O2AuthSDK.shared.setDeviceToken(token: registrationID ?? "registrationIDerror0x0x")
            }else{
                O2Logger.debug("registrationID获取失败，code:\(resCode)")
                O2AuthSDK.shared.setDeviceToken(token: registrationID ?? "registrationIDerror0x0x")
            }
        }
        
       
//        OOPlusButtonSubclass.register()
        OOTabBarHelper.initTabBarStyle()
        
        
        IQKeyboardManager.shared.enable = false
        
        return true
    }
    
    
    // MARK:- private func Jpush
    private func _setupJPUSH() {
        let entity = JPUSHRegisterEntity()
        entity.types = NSInteger(UNAuthorizationOptions.alert.rawValue) |
            NSInteger(UNAuthorizationOptions.sound.rawValue) |
            NSInteger(UNAuthorizationOptions.badge.rawValue)
        JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
    }
    
    // 旋转屏幕
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        if self.allowRotation {
//            return [.landscapeLeft, .landscapeRight, .portrait]
//        } else if self.rightRotation {
//            return .landscapeRight
//        }
        return .allButUpsideDown
    }
 
    
    //注册 APNs 获得device token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        let deviceTokenStr = deviceToken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined()
        DDLogDebug("获取到APNs deviceToken \(deviceTokenStr)")
        O2AuthSDK.shared.setApnsToken(token: deviceTokenStr)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidRegisterRemoteNotification"), object: deviceToken)
        JPUSHService.registerDeviceToken(deviceToken)
    }
    
   
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        DDLogDebug("open url :\(url.absoluteString)")
        return true
    }
    
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types.rawValue == 0 {
            AppConfigSettings.shared.notificationGranted = false
            AppConfigSettings.shared.firstGranted = true
            NotificationCenter.default.post(name: NSNotification.Name.init("SETTING_NOTI"), object: nil)
        }else{
            AppConfigSettings.shared.notificationGranted = true
            AppConfigSettings.shared.firstGranted = true
            NotificationCenter.default.post(name: NSNotification.Name.init("SETTING_NOTI"), object: nil)
        }
    }
    
    //实现注册 APNs 失败接口
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DDLogError("didFailToRegisterForRemoteNotificationsWithError: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        JPUSHService.handleRemoteNotification(userInfo)
        DDLogDebug("收到通知,\(userInfo)")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "AddNotificationCount"), object: nil)
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
//        application.cancelAllLocalNotifications()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
    }
   
    func applicationDidEnterBackground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
//        application.cancelAllLocalNotifications()
    }
    
    
    deinit {
        o2ReachabilityManager.stopListening()
    }
    
   
    // iOS 12 Support
     @available(iOS 12.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification!) {
        // open
        if (notification != nil && (notification?.request.trigger?.isKind(of: UNPushNotificationTrigger.self) == true) ) {
            //从通知界面直接进入应用
            DDLogInfo("从通知界面直接进入应用............")
        }else{
            //从通知设置界面进入应用
            DDLogInfo("从通知设置界面进入应用............")
        }
    }
    
    
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!,
                                 withCompletionHandler completionHandler: ((Int) -> Void)!) {
        let userInfo = notification.request.content.userInfo
        let request = notification.request // 收到推送的请求
        let content = request.content // 收到推送的消息内容
        let badge = content.badge // 推送消息的角标
        let body = content.body   // 推送消息体
        let sound = content.sound // 推送消息的声音
        let subtitle = content.subtitle // 推送消息的副标题
        let title = content.title // 推送消息的标题
        if (notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self))! {
            JPUSHService.handleRemoteNotification(userInfo)
        }else{
            //判断为本地通知
            O2Logger.debug("iOS10 前台收到本地通知:{\nbody:\(body),\ntitle:\(title),\nsubtitle:\(subtitle),\nbadge:\(badge ?? 0),\nsound:\(sound.debugDescription)")
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        JPUSHService.setBadge(0)
        completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue|UNNotificationPresentationOptions.badge.rawValue|UNNotificationPresentationOptions.sound.rawValue))
        
    }
    
    
    @available(iOS 10.0, *)
    func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
        
        let userInfo = response.notification.request.content.userInfo
        let request = response.notification.request // 收到推送的请求
        let content = request.content // 收到推送的消息内容
        
        let badge = content.badge // 推送消息的角标
        let body = content.body   // 推送消息体
        let sound = content.sound // 推送消息的声音
        let subtitle = content.subtitle // 推送消息的副标题
        let title = content.title // 推送消息的标题
        if (response.notification.request.trigger?.isKind(of: UNPushNotificationTrigger.self))! {
            JPUSHService.handleRemoteNotification(userInfo)
        }else{
            //判断为本地通知
            O2Logger.debug("iOS10 前台收到本地通知:{\nbody:\(body),\ntitle:\(title),\nsubtitle:\(subtitle),\nbadge:\(badge ?? 0),\nsound:\(sound.debugDescription)")
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        JPUSHService.setBadge(0)
        completionHandler()
    }
    
    
    
}
