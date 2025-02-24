//
//  BioAuthLoginViewController.swift
//  O2Platform
//
//  Created by FancyLou on 2019/3/11.
//  Copyright © 2019 zoneland. All rights reserved.
//

import UIKit
import CocoaLumberjack

/// 生物识别登录
class BioAuthLoginViewController: UIViewController {

    @IBOutlet weak var bioImageView: UIImageView!
    @IBOutlet weak var bioAuthBtn: OOBaseUIButton!
    
    
    var bioType = O2BiometryType.None
    var typeTitle = L10n.Login.verifyLoginNow
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bioAuthUser = AppConfigSettings.shared.bioAuthUser
        var isAuthed = false
        //判断是否当前绑定的服务器的
        if !bioAuthUser.isBlank {
            let array = bioAuthUser.split("^^")
            if array.count == 2 {
                if array[0] == O2AuthSDK.shared.bindUnit()?.id {
                    isAuthed = true
                }
            }
        }
        if !isAuthed {
            bioAuthBtn.isEnabled = false
        }else {
            bioType = O2BioLocalAuth.shared.checkBiometryType()
            switch bioType {
            case O2BiometryType.FaceID:
                typeTitle = L10n.Login.verifyLoginNow
                bioImageView.image = UIImage(named: "faceid")
                bioAuthBtn.setTitle(typeTitle, for: .normal)
                bioAuthBtn.isEnabled = true
                break
            case O2BiometryType.TouchID:
                typeTitle = L10n.Login.verifyLoginNow
                bioImageView.image = UIImage(named: "touchid")
                bioAuthBtn.setTitle(typeTitle, for: .normal)
                bioAuthBtn.isEnabled = true
                break
            case O2BiometryType.None:
                typeTitle = L10n.Login.login
                bioImageView.image = UIImage(named: "pic_o2_moren1")
                bioAuthBtn.setTitle(typeTitle, for: .normal)
                bioAuthBtn.isEnabled = false
                break
            }
        }
        
    }
    

    @IBAction func tapBioAuthLogin(_ sender: OOBaseUIButton) {
        
        if self.bioType != O2BiometryType.None {
            O2BioLocalAuth.shared.auth(reason: "\(typeTitle)", selfAuthTitle: L10n.Login.loginWithUsername, block: { (result, errorMsg) in
                switch result {
                case O2BioEvaluateResult.SUCCESS:
                   // login
                    self.loginO2OA()
                    break
                case O2BioEvaluateResult.FALLBACK:
                    self.back2Login()
                    break
                case O2BioEvaluateResult.LOCKED:
                    self.showSystemAlert(title: L10n.alert, message: L10n.Login.bioLocked, okHandler: { (action) in
                        //
                    })
                    break
                    
                case O2BioEvaluateResult.FAILURE:
                    DDLogError(errorMsg)
                    self.showError(title: L10n.Login.verificationFailed)
                    break
                }
            })
        }else {
            self.showError(title: L10n.Login.donotSupportBio)
        }

    }
    
    @objc private func back2Login() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "goBack2Login", sender: nil)
        }
    }
    
    private func loginO2OA() {
        self.showLoading()
        let bioAuthUser = AppConfigSettings.shared.bioAuthUser
        var userId = ""
        if !bioAuthUser.isBlank {
            let array = bioAuthUser.split("^^")
            if array.count == 2 {
                if array[0] == O2AuthSDK.shared.bindUnit()?.id {
                    userId = array[1]
                }
            }
        }
        if userId.isBlank {
            DDLogError("登录失败。。。用户名为空")
            self.showError(title: L10n.Login.loginFailUseOtherMethod)
        }else {
            O2AuthSDK.shared.faceRecognizeLogin(userId: userId, callback: { (result, msg) in
                if result {
                     self.hideLoading()
                    DispatchQueue.main.async {
                        let destVC = O2MainController.genernateVC()
//                        destVC.selectedIndex = 2
                        UIApplication.shared.keyWindow?.rootViewController = destVC
                        UIApplication.shared.keyWindow?.makeKeyAndVisible()
                    }
                }else {
                    DDLogError("登录失败。。。。。。。\(msg ?? "")")
                    self.showError(title: L10n.Login.loginFailUseOtherMethod)
                }
            })
        }
    }
    

}
