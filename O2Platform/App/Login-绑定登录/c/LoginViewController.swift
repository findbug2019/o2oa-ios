//
//  LoginViewController.swift
//  O2Platform
//
//  Created by 刘振兴 on 16/6/28.
//  Copyright © 2016年 zoneland. All rights reserved.
//

import UIKit

import AlamofireObjectMapper
import Alamofire
import SwiftyTimer
import SwiftyJSON
import ObjectMapper
import CocoaLumberjack
import Promises


/// 启动页面
class LoginViewController: UIViewController {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var startImage: UIImageView!
    var showView = 0
    
    var viewModel:OOLoginViewModel = {
        return OOLoginViewModel()
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load image
        if AppConfigSettings.shared.isFirstTime != true {
            let launchImage = OOCustomImageManager.default.loadImage(.launch_logo)
            iconImageView.image = launchImage
            iconImageView.isHidden = false
        }
        self.startImage.image = UIImage(named: "startImage")
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveBindCompleted(customNotification:)), name: OONotification.bindCompleted.notificationName, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showView += 1
        if AppConfigSettings.shared.isFirstTime == true {
            DDLogDebug("启动开始 isFirstTime is true")
            AppConfigSettings.shared.isFirstTime = false
            let pVC = OOGuidePageController(nibName: "OOGuidePageController", bundle: nil)
            //let navVC = ZLNavigationController(rootViewController: pVC)
            self.presentVC(pVC)
        }else{
            if self.showView == 1 {
                DDLogDebug("启动开始 isFirstTime is false")
                self.startFlowForPromise()
            }
        }
    }

    func startFlowForPromise() {
        //越狱检查
        if SecurityCheckManager.shared.isJailBroken() {
            self.showSystemAlert(title: L10n.alert, message: L10n.Login.jailbrokenAlertMessage) { (action) in
                DDLogError("已经越狱的机器，不进入app！")
            }
        }else {
            let unit = SampleEditionManger.shared.getCurrentUnit()
            O2AuthSDK.shared.launchInner(unit: unit) { (state, msg) in
                switch state {
                case .bindError:
                    //校验绑定结点信息错误
                    self.showError(title: msg ?? L10n.Login.UnknownError)
                    break
                case .loginError:
                    self.forwardToSegue("loginSystemSegue")
                    //自动登录出错
                    break
                case .unknownError:
                    self.showError(title: msg ?? L10n.Login.UnknownError)
                    break
                case .success:
                    //处理移动端应用
                    self.viewModel._saveAppConfigToDb()
                    //跳转到主页
                    let destVC = O2MainController.genernateVC()
                    UIApplication.shared.keyWindow?.rootViewController = destVC
                    UIApplication.shared.keyWindow?.makeKeyAndVisible()
                }
            }
            
//            if !O2IsConnect2Collect {
//                let unit = O2BindUnitModel()
//                if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"), let dic = NSDictionary(contentsOfFile: infoPath) {
//                    let o2Server = dic["o2 server"] as? NSDictionary
//                    let id = o2Server?["id"] as? String
//                    let name = o2Server?["name"] as? String
//                    let centerHost = o2Server?["centerHost"] as? String
//                    let centerContext = o2Server?["centerContext"] as? String
//                    let centerPort = o2Server?["centerPort"] as? Int
//                    let httpProtocol = o2Server?["httpProtocol"] as? String
//                    DDLogDebug("连接服务器：\(String(describing: name)) , host:\(String(describing: centerHost)) , context:\(String(describing: centerContext)), port:\(centerPort ?? 0), portocal:\(String(describing: httpProtocol)) ")
//                    if name == nil || centerHost == nil || centerContext == nil {
//                        self.showError(title:  L10n.Login.serverConfigInfoError)
//                        return
//                    }
//                    unit.id = id
//                    unit.centerContext = centerContext
//                    unit.centerHost = centerHost
//                    unit.centerPort = centerPort
//                    unit.httpProtocol = httpProtocol
//                    unit.name = name
//                }else {
//                    self.showError(title:  L10n.Login.ServerConfigIsEmpty)
//                    return
//                }
//
//                O2AuthSDK.shared.launchInner(unit: unit) { (state, msg) in
//                    switch state {
//                    case .bindError:
//                        //校验绑定结点信息错误
//                        self.showError(title: msg ?? L10n.Login.UnknownError)
//                        break
//                    case .loginError:
//                        self.forwardToSegue("loginSystemSegue")
//                        //自动登录出错
//                        break
//                    case .unknownError:
//                        self.showError(title: msg ?? L10n.Login.UnknownError)
//                        break
//                    case .success:
//                        //处理移动端应用
//                        self.viewModel._saveAppConfigToDb()
//                        //跳转到主页
//                        let destVC = O2MainController.genernateVC()
////                        destVC.selectedIndex = 2 // 首页选中 TODO 图标不亮。。。。。
//                        UIApplication.shared.keyWindow?.rootViewController = destVC
//                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
//                    }
//                }
//            }else {
//                //本地 -> 校验 -> 下载NodeAPI -> 下载configInfo -> 自动登录
//                O2AuthSDK.shared.launch { (state, msg) in
//                    switch state {
//                    case .bindError:
//                        //校验绑定结点信息错误
//                        self.forwardToSegue("bindPhoneSegue")
//                        break
//                    case .loginError:
//                        self.forwardToSegue("loginSystemSegue")
//                        //自动登录出错
//                        break
//                    case .unknownError:
//    //                    self.showError(title: msg ?? "未知错误！")
//                        self.needReBind(msg ?? L10n.Login.UnknownError)
//                        break
//                    case .success:
//                        //处理移动端应用
//                        self.viewModel._saveAppConfigToDb()
//                        //跳转到主页
//                        let destVC = O2MainController.genernateVC()
////                        destVC.selectedIndex = 2 // 首页选中 TODO 图标不亮。。。。。
//                        UIApplication.shared.keyWindow?.rootViewController = destVC
//                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
//                    }
//                }
//            }
            
            
        }
    }

    

    
    // MARK:- 到不同的segue
    func forwardToSegue(_ segueIdentitifer:String){
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: segueIdentitifer, sender: nil)
        }
    }
    
    @objc func receiveBindCompleted(customNotification:Notification){
        self.startFlowForPromise()
    }
    
    private func needReBind(_ error: String) {
        DispatchQueue.main.async {
            let confirmMessage = L10n.Login.rebindConfirmMessage(error)
            let alertController = UIAlertController(title: L10n.alert, message: confirmMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: L10n.Login.rebind, style: .default, handler: {(action) in
                self.rebind()
            })
            let cancelAction = UIAlertAction(title: L10n.cancel, style: .cancel, handler: {(action) in
                
            })
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    private func rebind() {
        O2AuthSDK.shared.clearAllInformationBeforeReBind(callback: { (result, msg) in
            DDLogInfo("清空登录和绑定信息，result:\(result), msg:\(msg ?? "")")
            DBManager.shared.removeAll()
            DispatchQueue.main.async {
                self.forwardToSegue("bindPhoneSegue")
            }
        })
    }
    

    @IBAction func unBindComplete(_ sender: UIStoryboardSegue){
        //绑定完成，执行
        self.startFlowForPromise()
    }
    
    @IBAction func show(_ sender: UITapGestureRecognizer) {
        //ProgressHUD.show("系统加截中，请稍候...", interaction: true)
    }
    
    //登录后返回执行此方法
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        segue.destination.modalPresentationStyle = .fullScreen
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}


