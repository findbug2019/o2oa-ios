//
//  CloudFileListController.swift
//  O2Platform
//
//  Created by FancyLou on 2019/10/17.
//  Copyright © 2019 zoneland. All rights reserved.
//

import UIKit
import CocoaLumberjack
import Promises
import QuickLook

//当前页面显示模式 normal：普通页面 shareToMe：分享给我的页面 myShare：我分享的页面 zone： 企业网盘共享工作区
enum FileListShowMode {
    case normal
    case shareToMe
    case myShare
    case zone
}

class CloudFileListController: CloudFileBaseVC {
    
    private let tableViewBottomConstraintName = "tableViewBottomConstraint"
    
    //当前页面显示模式
    var showMode: FileListShowMode = .normal
    //分享id 分享的二级以及后面的列表请求需要
    private var shareId: String = ""
    
    //面包屑 列表 可以传入顶级组织的OOFolder
    var breadcrumbList: [OOFolder] = []
   
    //table 数据
    private var dataList: [DataModel] = []
   
 
    //底部工具栏
    var toolbarView: UIToolbar!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var breadcrumBar: UIScrollView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //最后一个 设置title
        switch self.showMode {
        case .normal:
            self.title = L10n.cloudFiles // Languager.standardLanguager().string(key: "Cloud Files")
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "add"), style: .plain, target: self, action: #selector(addEvent))]
            break
        case .shareToMe:
            self.title = L10n.cloudFileShareToMe // Languager.standardLanguager().string(key: "Cloud File Share To Me")
            let btnName = L10n.cloudFileMyShareFiles // Languager.standardLanguager().string(key: "Cloud File My Share Files")
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: btnName, style: .plain, target: self, action: #selector(openMyShare))]
            break
        case .myShare:
            self.title = L10n.cloudFileMyShareFiles // Languager.standardLanguager().string(key: "Cloud File My Share Files")
            self.navigationItem.rightBarButtonItems = []
            break
        case .zone:
            // 打开共享工作区 第一条数据是 工作区的id和名称
            if self.breadcrumbList.count > 0 {
                let zone = self.breadcrumbList[0]
                self.title = zone.name ?? ""
                self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "add"), style: .plain, target: self, action: #selector(addEventInZone))]
            }
            break
        }
       
        //初始化数据
        if self.breadcrumbList.isEmpty {
            let all = OOFolder()
            all.id = ""
            all.name = L10n.allFile // Languager.standardLanguager().string(key: "All File")
            self.breadcrumbList.append(all)
        }
        //toolbar 初始化底部工具栏 先放在屏幕下面
        self.toolbarView = UIToolbar(frame: CGRect(x: 0, y: self.view.height - 44, width: self.view.width, height: 44))
        //初始化tableView
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UINib.init(nibName: "CFFileTableViewCell", bundle: nil), forCellReuseIdentifier: "CFFileTableViewCell")
        self.tableView.register(UINib.init(nibName: "CFFolderTableViewCell", bundle: nil), forCellReuseIdentifier: "CFFolderTableViewCell")
        self.loadListData()
        
    }
    
    
   // MARK: - private
    
    //点击新建按钮
    @objc private func addEvent() {
        var actions: [UIAlertAction] = []
        let uploadFile = L10n.uploadFile // Languager.standardLanguager().string(key: "Upload File")
        let newFile = UIAlertAction(title: uploadFile, style: .default) { (action) in
            self.choosePhotoAndUpload()
        }
        let newFolderTitle = L10n.newFolder // Languager.standardLanguager().string(key: "New Folder")
        let newFolder = UIAlertAction(title: newFolderTitle, style: .default) { (action) in
            self.createFolder()
        }
        actions.append(newFile)
        actions.append(newFolder)
        let newMsg = L10n.new // Languager.standardLanguager().string(key: "New")
        self.showSheetAction(title: "", message: newMsg, actions: actions)
    }
    
    //点击打开我分享的页面
    @objc private func openMyShare() {
        if let myShareVC = self.storyboard?.instantiateViewController(withIdentifier: "cloudFileListMultiModeVC") as? CloudFileListController {
            myShareVC.showMode = .myShare
            myShareVC.breadcrumbList = []
            self.pushVC(myShareVC)
        }
    }
    
    //点击新建按钮 企业网盘共享工作区使用
    @objc private func addEventInZone() {
        var actions: [UIAlertAction] = []
        let uploadFile = L10n.uploadFile // Languager.standardLanguager().string(key: "Upload File")
        let newFile = UIAlertAction(title: uploadFile, style: .default) { (action) in
            self.choosePhotoAndUploadV3()
        }
        let newFolderTitle = L10n.newFolder // Languager.standardLanguager().string(key: "New Folder")
        let newFolder = UIAlertAction(title: newFolderTitle, style: .default) { (action) in
            self.createFolderV3()
        }
        actions.append(newFile)
        actions.append(newFolder)
        let newMsg = L10n.new // Languager.standardLanguager().string(key: "New")
        self.showSheetAction(title: "", message: newMsg, actions: actions)
    }
    
    
    private func reloadUI() {
        self.refreshBottomToolBar()
        self.tableView.reloadData()
    }
    
    
    private func refreshBreadcrumbBar() {
        self.breadcrumBar.removeSubviews()
        var oX = CGFloat(4.0)
        let arrowW = CGFloat(24)
        let arrowH = CGFloat(32)
        breadcrumbList.forEachEnumerated { (index, bar) in
            let name = bar.name ?? ""
            var textColor:UIColor
            if self.breadcrumbList.count == (index+1) {
                textColor = UIColor(hex:"#666666")
            }else {
                textColor = base_color
            }
            let firstSize = name.getSize(with: 15)
            let oY = (self.breadcrumBar.bounds.height - firstSize.height) / 2
            let firstLabel = UILabel(frame: CGRect(x: CGFloat(oX), y: oY, width: firstSize.width, height: firstSize.height))
            firstLabel.textAlignment = .left
            let textAttributes = [NSAttributedString.Key.foregroundColor: textColor,NSAttributedString.Key.font:UIFont(name:"PingFangSC-Regular",size:15)!]
            firstLabel.attributedText = NSMutableAttributedString(string: name, attributes: textAttributes)
            firstLabel.sizeToFit()
            self.breadcrumBar.addSubview(firstLabel)
            oX += firstSize.width
            if self.breadcrumbList.count != (index+1) {
                let arrowY = (self.breadcrumBar.bounds.height - arrowH) / 2
                let arrowImage = UIImageView(frame: CGRect(x: CGFloat(oX), y: arrowY, width: arrowW, height: arrowH))
                arrowImage.image = UIImage(named: "arrow_r")
                arrowImage.contentMode = .scaleAspectFit
                self.breadcrumBar.addSubview(arrowImage)
                oX += arrowW
            }
            firstLabel.addTapGesture(action: { (rec) in
                DDLogDebug("点击了 \(index)")
                if self.breadcrumbList.count != (index+1) {
                    var newList:[OOFolder] = []
                    for i in 0...index {
                        newList.append(self.breadcrumbList[i])
                    }
                    self.breadcrumbList = newList
                    self.loadListData()
                }
            })
        }
        var size = self.breadcrumBar.contentSize;
        size.width = oX;
        self.breadcrumBar.showsHorizontalScrollIndicator = true;
        self.breadcrumBar.contentSize = size;
        self.breadcrumBar.bounces = true;
    }
    
    
    //底部工具栏中的单个按钮生成
    fileprivate func generateBottomButton(_ items: inout [UIBarButtonItem], name: String, tapCall: @escaping ()->Void) {
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        btn.setTitle(name, for: .normal)
        btn.setTitleColor(base_color, for: .normal)
        btn.addTapGesture { (tap) in
            tapCall()
        }
        let item = UIBarButtonItem(customView: btn)
        items.append(spaceItem)
        items.append(item)
        items.append(spaceItem)
    }
    
    //重新生成刷新底部工具栏和按钮
    private func refreshBottomToolBar() {
        let totalCount = self.checkedFileList.count + self.checkedFolderList.count + self.checkedV3FileList.count + self.checkedV3FolderList.count
        if totalCount > 0 {
            var items: [UIBarButtonItem] = []
            switch self.showMode {
            case .normal:
                if totalCount == 1 {
                    let reName = L10n.rename // Languager.standardLanguager().string(key: "Rename")
                    generateBottomButton(&items, name: reName, tapCall: {
                        self.renameOp()
                    })
                }
                //其他按钮 删除 移动 分享
                let deleteName = L10n.delete // Languager.standardLanguager().string(key: "Delete")
                self.generateBottomButton(&items, name: deleteName) {
                    self.deleteOp()
                }
                let moveName = L10n.move // Languager.standardLanguager().string(key: "Move")
                self.generateBottomButton(&items, name: moveName) {
                    self.moveOp()
                }
                let shareName = L10n.share // Languager.standardLanguager().string(key: "Share")
                self.generateBottomButton(&items, name: shareName) {
                    self.shareOp()
                }
                break
            case .myShare:
                //取消分享
                let deleteName = L10n.shareDelete // Languager.standardLanguager().string(key: "Share Delete")
                self.generateBottomButton(&items, name: deleteName) {
                    self.deleteMyShareFile()
                }
                break
            case .shareToMe:
                //屏蔽分享給我的
                let deleteName = L10n.shieldShare // Languager.standardLanguager().string(key: "Shield Share")
                self.generateBottomButton(&items, name: deleteName) {
                    self.shieldFileShareToMe()
                }
                break
            case .zone:
                 // 共享区 文件操作按钮生成
                if totalCount == 1 {
                    let reName = L10n.rename // 重命名
                    generateBottomButton(&items, name: reName, tapCall: {
                        self.renameV3()
                    })
                    let deleteName = L10n.delete // 删除
                    self.generateBottomButton(&items, name: deleteName) {
                        self.deleteV3()
                    }
                }
                let moveName = L10n.move // 移动
                self.generateBottomButton(&items, name: moveName) {
                    self.moveV3Inner()
                }
                let saveToMyPan = L10n.cloudFileV3ZoneFileSaveToPan
                self.generateBottomButton(&items, name: saveToMyPan) {
                    self.saveToMyPan()
                }
                break
            }
            
            self.layoutBottomBar(items: items)
        }else {
            var c = false
            self.view.constraints.forEach { (constraint) in
                if constraint.identifier == self.tableViewBottomConstraintName {
                    c = true
                }
            }
            if !c {
                let bottom = NSLayoutConstraint(item: self.view as Any, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.tableView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
                bottom.identifier = self.tableViewBottomConstraintName
                self.toolbarView.removeConstraints(self.toolbarView.constraints)
                self.toolbarView.removeFromSuperview()
                self.view.addConstraint(bottom)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    //布局底部工具栏
    private func layoutBottomBar(items: [UIBarButtonItem]) {
        DDLogDebug("layout bottom \(items.count)")
        let toolBarHeight = CGFloat(44.0)
        var bottomSpace = CGFloat(0)
        if iPhoneX {
            bottomSpace = CGFloat(-34.0)
        }
        if items.count > 0 {
            self.toolbarView.items = items
            self.view.addSubview(self.toolbarView)
            self.toolbarView.translatesAutoresizingMaskIntoConstraints = false
            //高度约束
            let heightC = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 0.0, constant: toolBarHeight)
            self.toolbarView.addConstraint(heightC)
            //底部约束
            let bottom = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: bottomSpace)
            //右边约束
            let trailing = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
            //左边约束
            let leading = NSLayoutConstraint(item: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
            self.view.addConstraints([bottom, leading, trailing])
            
            self.view.constraints.forEach { (constraint) in
                //删除原来tableView的底部约束
                
                if constraint.identifier == self.tableViewBottomConstraintName {
                    self.view.removeConstraint(constraint)
                }
            }
            //添加tableView和底部工具栏的约束
            let webcTop = NSLayoutConstraint(item: self.tableView as Any, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.toolbarView as Any, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
            self.view.addConstraint(webcTop)
            self.view.layoutIfNeeded()
        }
    }
    
    private func isFolderChecked(_ folder: OOFolder) -> Bool {
        return self.checkedFolderList.contains(folder)
    }
    private func isFolderV3Checked(_ folder: OOFolderV3) -> Bool {
        return self.checkedV3FolderList.contains(folder)
    }
    
    private func isFileChecked(_ file: OOAttachment) -> Bool {
        return self.checkedFileList.contains(file)
    }
    private func isFileV3Checked(_ file: OOAttachmentV3) -> Bool {
        return self.checkedV3FileList.contains(file)
    }
    
    
    // MARK: - 后台数据服务

    override func loadListData() {
        self.refreshBreadcrumbBar()
        self.showLoading()
        //清空数据
        self.dataList = []
        self.checkedFileList = []
        self.checkedFolderList = []
        self.checkedV3FileList = []
        self.checkedV3FolderList = []
        //分模式查询数据
        switch self.showMode {
        case .normal:
            let id = self.breadcrumbList[self.breadcrumbList.count-1].id ?? ""
            self.cFileVM.loadCloudFileList(folderParentId: id)
                .then { (result)  in
                    self.dataList = result
                    self.hideLoading()
                    self.reloadUI()
                }.catch { (error) in
                    DDLogError(error.localizedDescription)
                    self.hideLoading()
                    self.reloadUI()
            }
            break
        case .myShare:
            let folder = self.breadcrumbList[self.breadcrumbList.count-1]
            var parentId = ""
            //有fileId的是分享或者分享给我的 顶层列表对象才有
            if let fileId = folder.fileId, !fileId.isBlank {
                parentId = fileId
                self.shareId = folder.id ?? ""
            }else {
                parentId = folder.id ?? ""
            }
            self.cFileVM.loadMyShareList(folderParentId:  parentId, shareId: self.shareId)
                .then { (result)  in
                    self.dataList = result
                    self.hideLoading()
                    self.reloadUI()
                }.catch { (error) in
                    DDLogError(error.localizedDescription)
                    self.hideLoading()
                    self.reloadUI()
            }
            break
        case .shareToMe:
            let folder = self.breadcrumbList[self.breadcrumbList.count-1]
            var parentId = ""
            //有fileId的是分享或者分享给我的 顶层列表对象才有
            if let fileId = folder.fileId, !fileId.isBlank {
                parentId = fileId
                self.shareId = folder.id ?? ""
            }else {
                parentId = folder.id ?? ""
            }
            self.cFileVM.loadShareToMeList(folderParentId: parentId, shareId: self.shareId)
                .then { (result)  in
                    self.dataList = result
                    self.hideLoading()
                    self.reloadUI()
                }.catch { (error) in
                    DDLogError(error.localizedDescription)
                    self.hideLoading()
                    self.reloadUI()
            }
            break
        case .zone:
            let id = self.breadcrumbList[self.breadcrumbList.count-1].id ?? ""
            self.cFileVM.loadZoneFileListByFolderId(folderParentId: id)
                .then { (result)  in
                    self.dataList = result
                    self.hideLoading()
                    self.reloadUI()
                }.catch { (error) in
                    DDLogError(error.localizedDescription)
                    self.hideLoading()
                    self.reloadUI()
            }
            break
        }
        
    }
    
   
    
    //新建文件夹
    private func createFolder() {
        let newFolderTitle = L10n.newFolder // Languager.standardLanguager().string(key: "New Folder")
        self.showPromptAlert(title: newFolderTitle, message: "", inputText: "") { (ok, result) in
            if result != "" {
                let folderId = self.breadcrumbList.last?.id ?? ""
                self.cFileVM.createFolder(name: result, superior: folderId).then({ (id) in
                    self.loadListData()
                }).catch({ (error) in
                    DDLogError("创建文件失败,\(error.localizedDescription)")
                    let errTitle = L10n.createFolderErrorMessage // Languager.standardLanguager().string(key: "Create Folder Error Message")
                    self.showError(title: errTitle)
                })
            }
        }
    }
    
  
    //选择照片上传
    private func choosePhotoAndUpload() {
        self.choosePhotoWithImagePicker { (fileName, imageData) in
            self.showLoading()
            let folderId = self.breadcrumbList.last?.id ?? O2.O2_First_ID
            self.cFileVM.uploadFile(folderId: folderId, fileName: fileName, file: imageData)
                .then { result in
                    DDLogInfo("上传成功，\(result)")
                    self.hideLoading()
                    self.loadListData()
                }.catch { (error) in
                    DDLogError(error.localizedDescription)
                    self.hideLoading()
            }
        }
    }
    
    //取消分享
    private func deleteMyShareFile() {
        let totalCount = self.checkedFileList.count + self.checkedFolderList.count
        if totalCount > 0 {
            let alert = L10n.alert // Languager.standardLanguager().string(key: "Alert")
            let msg = L10n.deleteMyShareFileConfirmMessage // Languager.standardLanguager().string(key: "Delete My Share File Confirm Message")
            self.showDefaultConfirm(title: alert, message: msg) { (action) in
                var ids:[String] = []
                self.checkedFolderList.forEach { (folder) in
                    ids.append(folder.id!)
                }
                self.checkedFileList.forEach { (file) in
                    ids.append(file.id!)
                }
                self.cFileVM.deleteShareList(shareList: ids)
                    .then({ (result) in
                        self.loadListData()
                    }).catch({ (error) in
                        DDLogError(error.localizedDescription)
                        self.showError(title: error.localizedDescription)
                    })
            }
        }
    }
    
    //屏蔽分享給我的文件
    private func shieldFileShareToMe() {
        let totalCount = self.checkedFileList.count + self.checkedFolderList.count
        if totalCount > 0 {
            let alert = L10n.alert // Languager.standardLanguager().string(key: "Alert")
            let msg = L10n.shieldShareFileConfirmMessage // Languager.standardLanguager().string(key: "Shield Share File Confirm Message")
            self.showDefaultConfirm(title: alert, message: msg) { (action) in
                var ids:[String] = []
                self.checkedFolderList.forEach { (folder) in
                    ids.append(folder.id!)
                }
                self.checkedFileList.forEach { (file) in
                    ids.append(file.id!)
                }
                self.cFileVM.shieldShareList(shareList: ids)
                    .then({ (result) in
                         self.loadListData()
                    }).catch({ (error) in
                        DDLogError(error.localizedDescription)
                        self.showError(title: error.localizedDescription)
                    })
            }
        }
    }
    
     
     // 共享工作区内 新建文件夹
     private func createFolderV3() {
         let newFolderTitle = L10n.newFolder // Languager.standardLanguager().string(key: "New Folder")
         self.showPromptAlert(title: newFolderTitle, message: "", inputText: "") { (ok, result) in
             if result != "" {
                 let folderId = self.breadcrumbList.last?.id ?? ""
                 self.cFileVM.createFolderV3(name: result, superior: folderId).then({ (id) in
                     self.loadListData()
                 }).catch({ (error) in
                     DDLogError("创建文件失败,\(error.localizedDescription)")
                     let errTitle = L10n.createFolderErrorMessage
                     self.showError(title: errTitle)
                 })
             }
         }
     }
     
   
     // 共享工作区内 选择照片上传
     private func choosePhotoAndUploadV3() {
         self.choosePhotoWithImagePicker { (fileName, imageData) in
             self.showLoading()
             let folderId = self.breadcrumbList.last?.id ?? O2.O2_First_ID
             self.cFileVM.uploadFileV3(folderId: folderId, fileName: fileName, file: imageData)
                 .then { result in
                     DDLogInfo("上传成功，\(result)")
                     self.hideLoading()
                     self.loadListData()
                 }.catch { (error) in
                     DDLogError(error.localizedDescription)
                     self.hideLoading()
             }
         }
     }
    // 共享工作区内文件、文件夹重命名
    private func renameV3() {
        let rename = L10n.rename // Languager.standardLanguager().string(key: "Rename")
        if self.checkedV3FileList.count > 0 {
            let file = self.checkedV3FileList.first!
            if file.isAdmin == true || file.isEditor == true || file.isCreator == true {
                let name = file.name ?? ""
                self.showPromptAlert(title: rename, message: "\(rename) \(name)", inputText: name) { (action, result) in
                    if result.isBlank {
                        let msg = L10n.emptyNameErrorMessage // Languager.standardLanguager().string(key: "Empty name Error Message")
                        self.showError(title: msg)
                    }else {
                        self.cFileVM.renameFileV3(id: file.id ?? "", newName: result).then({ (result) in
                            self.loadListData()
                        }).catch({ (error) in
                            DDLogError(error.localizedDescription)
                            self.showError(title: error.localizedDescription)
                        })
                    }
                }
            } else {
                self.showError(title: L10n.cloudFileV3ZoneFileNoPermissionUpdate)
            }
        } else if self.checkedV3FolderList.count > 0 {
            let folder = self.checkedV3FolderList.first!
            if folder.isAdmin == true || folder.isEditor == true || folder.isCreator == true {
                let name = folder.name ?? ""
                self.showPromptAlert(title: rename, message: "\(rename) \(name)", inputText: name) { (action, result) in
                    if result.isBlank {
                        let msg = L10n.emptyNameErrorMessage // Languager.standardLanguager().string(key: "Empty name Error Message")
                        self.showError(title: msg)
                    }else {
                        self.cFileVM.renameFolderV3(id: folder.id ?? "", newName: result).then({ (result) in
                            self.loadListData()
                        }).catch({ (error) in
                            DDLogError(error.localizedDescription)
                            self.showError(title: error.localizedDescription)
                        })
                    }
                }
            } else {
                self.showError(title: L10n.cloudFileV3ZoneFileNoPermissionUpdate)
            }
        }
    }
    // 共享工作区内文件、文件夹删除
    private func deleteV3() {
        if self.checkedV3FileList.count > 0 {
            let file = self.checkedV3FileList.first!
            if file.isAdmin == true || file.isEditor == true || file.isCreator == true {
                let alert = L10n.alert
                let msg = L10n.deleteItemsConfirmMessage
                self.showDefaultConfirm(title: alert, message: msg) { (action) in
                    self.cFileVM.deleteFileV3(id: file.id ?? "")
                        .then({ (result) in
                            if result {
                                self.loadListData()
                            }
                        }).catch({ (error) in
                            DDLogError(error.localizedDescription)
                            self.showError(title: error.localizedDescription)
                        })
                }
                
                
            } else {
                self.showError(title: L10n.cloudFileV3ZoneFileNoPermissionDelete)
            }
        } else if self.checkedV3FolderList.count > 0 {
            let folder = self.checkedV3FolderList.first!
            if folder.isAdmin == true || folder.isEditor == true || folder.isCreator == true {
                let alert = L10n.alert
                let msg = L10n.deleteItemsConfirmMessage
                self.showDefaultConfirm(title: alert, message: msg) { (action) in
                    self.cFileVM.deleteFolderV3(id: folder.id ?? "")
                        .then({ (result) in
                            if result {
                                self.loadListData()
                            }
                        }).catch({ (error) in
                            DDLogError(error.localizedDescription)
                            self.showError(title: error.localizedDescription)
                        })
                }
            } else {
                self.showError(title: L10n.cloudFileV3ZoneFileNoPermissionDelete)
            }
        }
    }
    // 共享工作区内文件、文件夹移动
    private func moveV3Inner() {
        DDLogDebug("企业网盘 文件、文件夹 移动")
        let totalCount = self.checkedV3FileList.count + self.checkedV3FolderList.count
        if totalCount > 0 {
            if let first = self.breadcrumbList.first, let vc = CloudFileMoveFolderV3Controller.chooseFolderV3VC({ folder in
                self.showLoading()
                self.cFileVM.moveV3(folderList: self.checkedV3FolderList, fileList: self.checkedV3FileList, destFolder: folder)
                    .then({ (result) in
                        DDLogInfo("移动成功，\(result)")
                        self.hideLoading()
                        if result {
                            self.loadListData()
                        }
                    }).catch { (error) in
                        DDLogError(error.localizedDescription)
                        self.hideLoading()
                }
            }, zoneId: first.id ?? "" , zoneName: first.name ?? ""){
                self.pushVC(vc)
            }
        }
    }
    // 将共享工作区的文件、文件夹保存到我的网盘
    private func saveToMyPan() {
        DDLogDebug("保存到我的网盘")
        let totalCount = self.checkedV3FileList.count + self.checkedV3FolderList.count
        if totalCount > 0 {
            if let vc = CloudFileMoveFolderController.chooseFolderVC({ (folder) in
                self.showLoading()
                self.cFileVM.saveToMyPan(parentId: folder.id ?? "", files: self.checkedV3FileList.map({ att in
                    att.id ?? ""
                }), folders: self.checkedV3FolderList.map({ fo in
                    fo.id ?? ""
                }))
                    .then({ (result) in
                        DDLogInfo("保存到我的网盘成功，\(result)")
                        self.hideLoading()
                        if result {
                            self.loadListData()
                        }
                    }).catch { (error) in
                        DDLogError(error.localizedDescription)
                        self.hideLoading()
                }
            }){
                self.pushVC(vc)
            }
        }
    }
   
}

// MARK: - UITableView
extension CloudFileListController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect.zero)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.dataList[indexPath.row]
        // 分享列表的时候 二级一下目录文件不能显示checkbox 它们是不能操作的
        var isShowCheckBox = true
        if (self.showMode == .myShare || self.showMode == .shareToMe) && self.breadcrumbList.count > 1 {
            isShowCheckBox = false
        }
        if item is OOFolder {
            let folder = item as! OOFolder
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CFFolderTableViewCell", for: indexPath) as? CFFolderTableViewCell {
                cell.clickdelegate = self
                cell.setData(folder: folder, checked: self.isFolderChecked(folder), isShowCheck: isShowCheckBox)
                return cell
            } else {
                return UITableViewCell()
            }
        } else if item is OOAttachment {
            let file = item as! OOAttachment
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CFFileTableViewCell", for: indexPath) as? CFFileTableViewCell {
                cell.clickdelegate = self
                cell.setData(file: file, checked: self.isFileChecked(file), isShowCheck: isShowCheckBox)
                return cell
            } else {
                return UITableViewCell()
            }
        } else if item is OOFolderV3 {
            let folder = item as! OOFolderV3
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CFFolderTableViewCell", for: indexPath) as? CFFolderTableViewCell {
                cell.clickdelegate = self
                cell.setDataV3(folder: folder, checked: self.isFolderV3Checked(folder), isShowCheck: isShowCheckBox)
                return cell
            } else {
                return UITableViewCell()
            }
        } else if item is OOAttachmentV3 {
            let file = item as! OOAttachmentV3
            if let cell = tableView.dequeueReusableCell(withIdentifier: "CFFileTableViewCell", for: indexPath) as? CFFileTableViewCell {
                cell.clickdelegate = self
                cell.setDataV3(file: file, checked: self.isFileV3Checked(file), isShowCheck: isShowCheckBox)
                return cell
            } else {
                return UITableViewCell()
            }
        }  else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //点击处理
        let item = self.dataList[indexPath.row]
        if item is OOFolder { //点击文件夹进入下一层
            let folder = item as! OOFolder
            self.breadcrumbList.append(folder)
            self.loadListData()
        } else if item is OOAttachment { //点击文件
            let file = item as! OOAttachment
            if let trueId = file.fileId {
                file.id = trueId
            }
            self.clickFile(file: file)
        } else if item is OOFolderV3 { //点击文件夹进入下一层
            let folderV3 = item as! OOFolderV3
            let folder = OOFolder()
            folder.id = folderV3.id
            folder.name = folderV3.name
            self.breadcrumbList.append(folder)
            self.loadListData()
        } else if item is OOAttachmentV3 { //点击文件
            let file = item as! OOAttachmentV3
            self.clickFileV3(file: file)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
}


// MARK: - Ext CloudFileCheckClickDelegate
extension CloudFileListController: CloudFileCheckClickDelegate {
    func clickFolderV3(_ folder: OOFolderV3) {
        DDLogDebug("click folder v3")
        if self.checkedV3FolderList.contains(folder) {
            self.checkedV3FolderList.removeFirst(folder)
        }else {
            self.checkedV3FolderList.append(folder)
        }
        self.reloadUI()
    }
    
    func clickFileV3(_ file: OOAttachmentV3) {
        DDLogDebug("click file v3")
        if self.checkedV3FileList.contains(file) {
            self.checkedV3FileList.removeFirst(file)
        }else {
            self.checkedV3FileList.append(file)
        }
        self.reloadUI()
    }
    
    func clickFolder(_ folder: OOFolder) {
        DDLogDebug("clci folder")
        if self.checkedFolderList.contains(folder) {
            self.checkedFolderList.removeFirst(folder)
        }else {
            self.checkedFolderList.append(folder)
        }
        self.reloadUI()
    }
    
    func clickFile(_ file: OOAttachment) {
        DDLogDebug("click file")
        if self.checkedFileList.contains(file) {
            self.checkedFileList.removeFirst(file)
        }else {
            self.checkedFileList.append(file)
        }
        self.reloadUI()
    }
}
