//
//  CMSItemDetailViewController.swift
//  O2Platform
//
//  Created by 刘振兴 on 2016/12/9.
//  Copyright © 2016年 zoneland. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import AlamofireObjectMapper

import ObjectMapper
import QuickLook
import Photos
import CocoaLumberjack

class CMSItemDetailViewController: BaseWebViewUIViewController {
    
    
    
    fileprivate var currentFileURLS:[NSURL] = []
 
    var itemData:CMSCategoryItemData? {
        didSet {
            title = itemData?.title
            if itemData?.readonly != nil && itemData?.readonly == false {
                itemUrl = AppDelegate.o2Collect.genrateURLWithWebContextKey(DesktopContext.DesktopContextKey, query: DesktopContext.cmsItemDetailEditHtml, parameter: ["##documentId##":itemData?.id as AnyObject])!
            } else {
                itemUrl = AppDelegate.o2Collect.genrateURLWithWebContextKey(DesktopContext.DesktopContextKey, query: DesktopContext.cmsItemDetailQuery, parameter: ["##documentId##":itemData?.id as AnyObject])!
            }
        }
    }
    
    var documentId:String?{
        didSet {
            itemUrl = AppDelegate.o2Collect.genrateURLWithWebContextKey(DesktopContext.DesktopContextKey, query: DesktopContext.cmsItemDetailQuery, parameter: ["##documentId##":documentId as AnyObject])!
        }
    }
    
    var itemUrl = ""
    
    var fromCreateDocVC = false
    //cms操作control
    var myControl: [String : AnyObject]?
    //cms底部操作按钮 toolbar
    var toolbarView: UIToolbar!
    //webview的容器
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var progressView: UIProgressView!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //监控进度
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.isHidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //自定义返回按钮
        self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_fanhui"), style: .plain, target: self, action: #selector(goBack))
        self.navigationItem.leftItemsSupplementBackButton = true
        // 底部操作按钮toolbar
        self.toolbarView = UIToolbar(frame: CGRect(x: 0, y: self.view.height - 44, width: self.view.width, height: 44))


        
        //先添加js注入
        addScriptMessageHandler(key: "cmsFormLoaded", handler: self)
        addScriptMessageHandler(key: "uploadAttachment", handler: self)
        addScriptMessageHandler(key: "uploadAttachmentForDatagrid", handler: self)
        addScriptMessageHandler(key: "downloadAttachment", handler: self)
        addScriptMessageHandler(key: "replaceAttachment", handler: self)
        addScriptMessageHandler(key: "replaceAttachmentForDatagrid", handler: self)
        addScriptMessageHandler(key: "openDocument", handler: self)
        addScriptMessageHandler(key: "closeDocumentWindow", handler: self)
        self.theWebView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func theWebView(){
        super.theWebView()
        
        self.webViewContainer.addSubview(self.webView)
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: self.webView as Any, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.webViewContainer, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: self.webView as Any, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.webViewContainer, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: self.webView as Any, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.webViewContainer, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
        let leading = NSLayoutConstraint(item: self.webView as Any, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.webViewContainer, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
        self.webViewContainer.addConstraints([top, bottom, trailing, leading])
       
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        loadItemDetail()
    }
    
    @objc func goBack() {
        if self.fromCreateDocVC {//创建文档页面跳过来的 返回的时候就多跳一级
            self.performSegue(withIdentifier: "back2DocumentListSegue", sender: nil)
        } else {
          self.navigationController?.popViewController(animated: false)
        }
    }
    
    
    
    private func loadItemDetail()  {
        DDLogDebug("url:\(itemUrl)")
        if let urlR = URL(string: itemUrl) {
            let req = URLRequest(url: urlR)
            webView.load(req)
        }else {
            webView.loadHTMLString("<h2>没有获取到正确的URL！</h2>", baseURL: nil)
        }
    }
    
    @objc private func qlCloseWindow(){
        self.dismiss(animated: true, completion: {
            
        })
    }
    
    private func setupBottomToolbar() {
        var items: [UIBarButtonItem] = []
        if self.myControl != nil {
            let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            if let allowDelete = self.myControl!["allowDeleteDocument"] as? Bool {
                if allowDelete { //删除文档
                    DDLogDebug("删除文档。。。。。。。。。。。。。。。。。。。。。。安装按钮")
                    let deleteBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                    deleteBtn.setTitle("删除", for: .normal)
                    deleteBtn.setTitleColor(base_color, for: .normal)
                    deleteBtn.addTapGesture { (tap) in
                        self.itemBtnDocDeleteAction()
                    }
                    let deleteItem = UIBarButtonItem(customView: deleteBtn)
                    items.append(spaceItem)
                    items.append(deleteItem)
                    items.append(spaceItem)
                }
            }
            if let allowPublishDocument = self.myControl!["allowPublishDocument"] as? Bool {
                if allowPublishDocument { //发布文档
                    DDLogDebug("发布文档。。。。。。。。。。。。。。。。。。。。。。安装按钮")
                    let publishBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                    publishBtn.setTitle("发布", for: .normal)
                    publishBtn.setTitleColor(base_color, for: .normal)
                    publishBtn.addTapGesture { (tap) in
                        self.itemBtnDocPublishAction()
                    }
                    let publishItem = UIBarButtonItem(customView: publishBtn)
                    items.append(spaceItem)
                    items.append(publishItem)
                    items.append(spaceItem)
                }
            }
            self.layoutBottomBar(items: items)
        }
    }
    private func layoutBottomBar(items: [UIBarButtonItem]) {
        if items.count > 0 {
            self.toolbarView.items = items
            self.view.addSubview(self.toolbarView)
            self.toolbarView.translatesAutoresizingMaskIntoConstraints = false
            let heightC = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 0.0, constant: 44)
            self.toolbarView.addConstraint(heightC)
            let bottom = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
            let trailing = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
            let leading = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
            self.view.addConstraints([bottom, leading, trailing])
            self.view.constraints.forEach { (constraint) in
                if constraint.identifier == "webViewContainerBottom" {
                    self.view.removeConstraint(constraint)
                }
            }
            let webcTop = NSLayoutConstraint(item: self.webViewContainer as Any, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.toolbarView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
            self.view.addConstraint(webcTop)
            self.view.layoutIfNeeded()
        }
    }
    
    //删除文档
    private func itemBtnDocDeleteAction() {
        self.showDefaultConfirm(title: "提示", message: "你确定要删除当前文档？") { (action) in
            let callJS = "layout.appForm.deleteDocumentForMobile()"
            self.webView.evaluateJavaScript(callJS, completionHandler: { (result, err) in
                //
            })
        }
    }
    //发布文档 layout.appForm.publishDocument()
    private func itemBtnDocPublishAction() {
        let callJS = "layout.appForm.publishDocument()"
        self.webView.evaluateJavaScript(callJS, completionHandler: { (result, err) in
            //
        })
    }
    
}

extension CMSItemDetailViewController:WKNavigationDelegate,WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        DDLogDebug("didFailProvisionalNavigation \(String(describing: navigation))  error = \(error)")
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DDLogDebug("didStartProvisionalNavigation \(String(describing: navigation))")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DDLogDebug("didCommit")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DDLogDebug("didFinish")
        //self.setupData()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        DDLogDebug("didFail")
        DDLogError(error.localizedDescription)
    }
    
    
}

//MARK: js脚本
extension CMSItemDetailViewController: O2WKScriptMessageHandlerImplement {
    func userController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let name = message.name
        switch name {
        case "cmsFormLoaded":
            DDLogDebug("cmsFormLoaded start。。。。")
            if let newControls = (message.body as? NSString) {
                let str = newControls as String
                DDLogDebug("cmsFormLoaded , controls :\(str)")
                let json = JSON.init(parseJSON: str)
                self.myControl = json.dictionaryObject! as [String: AnyObject]
                self.setupBottomToolbar()
            }
            break
        case "uploadAttachment":
            ZonePermissions.requestImagePickerAuthorization(callback: { (zoneStatus) in
                if zoneStatus == ZoneAuthorizationStatus.zAuthorizationStatusAuthorized {
                    if let body = (message.body as?  NSDictionary), let site = body["site"] as? String {
                        self.uploadAttachment(site)
                    }else {
                        self.showError(title: "参数传入错误，无法上传！")
                    }
                }else {
                    self.gotoApplicationSettings(alertMessage: "需要照片允许访问权限，是否跳转到手机设置页面开启相机权限？")
                }
            })
            break
        case "uploadAttachmentForDatagrid":
            ZonePermissions.requestImagePickerAuthorization(callback: { (zoneStatus) in
                if zoneStatus == ZoneAuthorizationStatus.zAuthorizationStatusAuthorized {
                    if let body = (message.body as?  NSDictionary), let site = body["site"] as? String, let param = body["param"] as? String  {
                        self.uploadAttachment(site, param: param)
                    }else {
                        self.showError(title: "参数传入错误，无法上传！")
                    }
                    
                }else {
                    self.gotoApplicationSettings(alertMessage: "需要照片允许访问权限，是否跳转到手机设置页面开启相机权限？")
                }
            })
            break
        case "downloadAttachment":
            let attachmentId = (message.body as! NSDictionary)["id"]
            self.downloadAttachment(attachmentId as! String)
            break
        case "replaceAttachment":
            if let body = (message.body as? NSDictionary), let attachmentId = body["id"] as? String, let site = body["site"] as? String {
                self.replaceAttachment(attachmentId, site)
            }else {
                self.showError(title: "参数传入错误，无法替换！")
            }
            
            break
        case "replaceAttachmentForDatagrid":
            if let body = (message.body as? NSDictionary), let attachmentId = body["id"] as? String, let site = body["site"] as? String, let param = body["param"] as? String {
                self.replaceAttachment(attachmentId, site, param: param)
            }else {
                self.showError(title: "参数传入错误，无法替换！")
            }
            break
        case "openDocument":
            let url = (message.body as! NSString)
            self.downloadDocumentAndPreview(String(url))
            break
        case "closeDocumentWindow":
            self.goBack()
            break
        default:
            DDLogError("未知方法名：\(name)！")
            break
        }
    }
    
    
    
    //上传附件
    private func uploadAttachment(_ site:String, param: String = ""){
        //选择附件上传
        var id = ""
        if self.documentId != nil {
            id = self.documentId!
        }else {
            id = self.itemData!.id!
        }
        let updloadURL = AppDelegate.o2Collect.generateURLWithAppContextKey(CMSContext.cmsContextKey, query: CMSContext.cmsAttachmentUpload, parameter: ["##docId##":id as AnyObject])
        self.uploadAttachment(site, uploadURL: updloadURL!, param: param)
    }
    private func uploadAttachment(_ site:String,uploadURL url:String, param: String = "") {
        
        self.choosePhotoWithImagePicker { (fName, imageData) in
            DispatchQueue.main.async {
                self.showLoading(title: "上传中...")
            }
            DispatchQueue.global(qos: .userInitiated).async {
              // MARK: - 这里需要修改
                AF.upload(multipartFormData: { (mData) in
                    mData.append(imageData, withName: "file", fileName: fName, mimeType: "application/octet-stream")
                    let siteData = site.data(using: String.Encoding.utf8, allowLossyConversion: false)
                    mData.append(siteData!, withName: "site")
                }, to: url).responseJSON(completionHandler: { (reponse) in
                    if let err = reponse.error {
                        DispatchQueue.main.async {
                            DDLogError(err.localizedDescription)
                            self.showError(title: "上传失败")
                        }
                    }else {
                        let attachId = JSON(reponse.data)["data"]["id"].string!
                        DispatchQueue.main.async {
                            if param == "" {
                                let callJS = "layout.appForm.uploadedAttachment(\"\(site)\", \"\(attachId)\")"
                                self.webView.evaluateJavaScript(callJS, completionHandler: { (result, err) in
                                })
                            } else {
                                let callJS = "layout.appForm.uploadedAttachmentDatagrid(\"\(site)\", \"\(attachId)\", \"\(param)\")"
                                self.webView.evaluateJavaScript(callJS, completionHandler: { (result, err) in
                                })
                            }
                            self.showSuccess(title: "上传成功")
                        }
                    }
                })
            }
        }
    }
    
    //下载预览附件
    private func downloadAttachment(_ attachmentId:String){
        //文档id
        var id: String?
        if self.documentId != nil {
            id = self.documentId
        }else {
            id = self.itemData?.id
        }
        if id == nil {
            self.showError(title: "下载文件出错")
            return
        }
        //
        let attachInfoURL = AppDelegate.o2Collect.generateURLWithAppContextKey(CMSContext.cmsContextKey, query: CMSContext.cmsAttachmentGET, parameter: ["##attachId##":attachmentId as AnyObject, "##documentId##": id as AnyObject])
        //附件下载链接
        let downURL = AppDelegate.o2Collect.generateURLWithAppContextKey(CMSContext.cmsContextKey, query: CMSContext.cmsAttachmentDownloadNewQuery, parameter: ["##attachId##":attachmentId as AnyObject])
        self.showLoading(title: "下载中...")
        // 先获取附件对象
        AF.request(attachInfoURL!).responseJSON { (response) in
            switch response.result {
            case .success(let val):
                let info = Mapper<CMSAttachmentInfoResponse>().map(JSONString: JSON(val).description)
                if let fileName = info?.data?.name {
                    //执行下载
                    let destination: DownloadRequest.Destination = { _, _ in
                        let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                        let fileURL = documentsURL.appendingPathComponent(fileName)
                        return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                    }
                    //然后下载附件
                    AF.download(downURL!, to: destination).response(completionHandler: { (response) in
                        if response.error == nil , let fileurl = response.fileURL?.path {
                            //打开文件
                            DispatchQueue.main.async {
                                self.hideLoading()
                                self.previewDoc(path: fileurl)
                            }
                        }else{
                            DispatchQueue.main.async {
                                self.showError(title: "下载文件出错")
                            }
                        }
                    })
                }else {
                    DispatchQueue.main.async {
                        self.showError(title: "下载文件出错")
                    }
                }
                break
            case .failure(let err):
                DDLogError(err.localizedDescription)
                DispatchQueue.main.async {
                    self.showError(title: "下载文件出错")
                }
                break
            }
        }
        
         
    }
    
    //替换附件
    private func replaceAttachment(_ attachmentId:String, _ site:String, param: String = ""){
        var id = ""
        if self.documentId != nil {
            id = self.documentId!
        }else {
            id = self.itemData!.id!
        }
        let replaceURL = AppDelegate.o2Collect.generateURLWithAppContextKey(CMSContext.cmsContextKey, query: CMSContext.cmsAttachmentReplace, parameter: ["##attachId##":attachmentId as AnyObject,"##docId##": id as AnyObject])!
        self.replaceAttachment(site, attachmentId, replaceURL: replaceURL, param: param)
    }
    
    
    
    /**
     * 下载公文 并阅览
     **/
    private func downloadDocumentAndPreview(_ url: String) {
        DDLogDebug("文档下载地址：\(url)")
        self.showLoading(title: "下载中...")
        // 文件地址
        let localFileDestination: DownloadRequest.Destination = { _, response in
            let documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(response.suggestedFilename!)
            // 有重名文件就删除重建
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        AF.download(url, to: localFileDestination).response(completionHandler: { (response) in
            if response.error == nil , let fileurl = response.fileURL?.path {
                DDLogDebug("文件地址：\(fileurl)")
                //打开文件
                DispatchQueue.main.async {
                    self.hideLoading()
                    self.previewDoc(path: fileurl)
                }
            }else{
                let msg = response.error?.localizedDescription ?? ""
                DDLogError("下载文件出错，\(msg)")
                DispatchQueue.main.async {
                    self.showError(title: "预览文件出错")
                }
            }
        })
    }
    
//    private func previewAttachment(_ url:String){
//        let currentURL = NSURL(fileURLWithPath: url)
//        if QLPreviewController.canPreview(currentURL) {
//            self.qlController.currentFileURLS.removeAll(keepingCapacity: true)
//            self.qlController.currentFileURLS.append(currentURL)
//            self.qlController.reloadData()
//            if #available(iOS 10, *) {
//                let navVC = ZLNormalNavViewController(rootViewController: qlController)
//                qlController.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: qlController, action: #selector(qlController.qlCloseWindow))
//                self.presentVC(navVC)
//            }else{
//                self.pushVC(qlController)
//            }
//        }else{
//            self.showError(title: "此文件无法预览，请在PC端查看")
//        }
//
//    }
    
    
    private func replaceAttachment(_ site:String,_ attachmentId:String,replaceURL url:String, param: String = ""){
        
        self.choosePhotoWithImagePicker { (fName, imageData) in
            DispatchQueue.main.async {
                self.showLoading(title: "上传中...")
            }
            AF.upload(multipartFormData: { (mData) in
                //mData.append(fileURL, withName: "file")
                mData.append(imageData, withName: "file", fileName: fName, mimeType: "application/octet-stream")
                let siteData = site.data(using: String.Encoding.utf8, allowLossyConversion: false)
                mData.append(siteData!, withName: "site")
            }, to: url, method: .put).responseJSON { (response) in
                if let err = response.error {
                    DispatchQueue.main.async {
                        DDLogError(err.localizedDescription)
                        self.showError(title: "替换失败")
                    }
                }else {
                    DispatchQueue.main.async {
                        if param == "" {
                            let callJS = "layout.appForm.replacedAttachment(\"\(site)\", \"\(attachmentId)\")"
                            self.webView.evaluateJavaScript(callJS, completionHandler: { (result, err) in
                                
                            })
                        } else {
                            let callJS = "layout.appForm.replacedAttachmentDatagrid(\"\(site)\", \"\(attachmentId)\", \"\(param)\")"
                            self.webView.evaluateJavaScript(callJS, completionHandler: { (result, err) in
                                
                            })
                        }
                        self.showSuccess(title: "替换成功")
                    }
                }
            }
        }
        
    }
    
    
}
