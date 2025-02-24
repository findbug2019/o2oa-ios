//
//  OOMeetingInforController.swift
//  o2app
//
//  Created by 刘振兴 on 2018/1/4.
//  Copyright © 2018年 zone. All rights reserved.
//

import UIKit
import EmptyDataSet_Swift
import Promises
import CocoaLumberjack

private let meetingIdentifier = "OOMeetingInforItemCell"

class OOMeetingInforController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var sectionHeight = CGFloat(172.0)

    private var hSectionHeight = CGFloat(387.0)

    private var sFlag = false
    
    private var currentMonthDay: Date?
    private var currentSelectDay: Date?

    private var config: OOMeetingConfigInfo? = nil

    //指定日期的所有会议
    private var theMeetingsByDay: [OOMeetingInfo] = []

    private lazy var viewModel: OOMeetingMainViewModel = {
        return OOMeetingMainViewModel()
    }()

    private var headerView: OOMeetingInforHeaderView = {
        let view = Bundle.main.loadNibNamed("OOMeetingInforHeaderView", owner: self, options: nil)?.first as! OOMeetingInforHeaderView
        return view
    }()

    private lazy var createView: O2BBSCreatorView = {
        let view = Bundle.main.loadNibNamed("O2BBSCreatorView", owner: self, options: nil)?.first as! O2BBSCreatorView
        view.iconImage = #imageLiteral(resourceName: "icon_collection_pencil")
        view.delegate = self
        view.frame = CGRect(x: kScreenW - 50 - 25, y: kScreenH - 50 - 25 - 40, width: 50, height: 50)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarItem?.selectedImage = O2ThemeManager.image(for: "Icon.icon_huiyi_pro")
        tableView.register(UINib.init(nibName: "OOMeetingInforItemCell", bundle: nil), forCellReuseIdentifier: meetingIdentifier)
        headerView.delegate = self
        //headerView.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: 172)
        //tableView.tableHeaderView = headerView
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
            self.loadData()
        })
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        loadMeetConfig()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        createView.removeFromSuperview()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMeetingDetail" {
            if let vc = segue.destination as?  OOMeetingDetailViewController {
                if let meeting = sender as? OOMeetingInfo {
                    vc.meetingInfo = meeting
                }
            }
        }
    }

    func loadMeetConfig() {
        viewModel.loadMeetingConfig().then { (config) in
            self.config = config
            if let c = self.config {
                O2UserDefaults.shared.meetingConfig = c
                if c.mobileCreateEnable == true {
                    DispatchQueue.main.async {
                        UIApplication.shared.windows.first?.addSubview(self.createView)
                    }
                }
            }
        }.catch { (error) in
            DDLogError("会议配置获取异常, \(error)")
        }
    }

    func loadData() {
        self.showLoading()
        if self.currentMonthDay == nil {
            self.currentMonthDay = Date()
        }
        if self.currentSelectDay == nil {
            self.currentSelectDay = Date()
        }
        all(viewModel.getMeetingsByYearAndMonth(self.currentMonthDay!), viewModel.getMeetingByTheDay(self.currentSelectDay!))
            .always {
                self.hideLoading()
                if self.tableView.mj_header.isRefreshing() {
                    self.tableView.mj_header.endRefreshing()
                }
                //self.tableView.reloadData()
            }
        .then { (result) in
            DispatchQueue.main.async {
                self.headerView.eventsByDate = result.0 as? [String: [OOMeetingInfo]]
                self.viewModel.theMeetingsByDay.removeAll()
                self.viewModel.theMeetingsByDay.append(contentsOf: result.1)
                self.tableView.reloadData()
            }
        }.catch { (myerror) in
            let customError = myerror as! OOAppError
            self.showError(title: customError.failureReason ?? "")
        }
    }


    func loadCurrentMonthCalendar(_ theDate: Date?) {
        self.showLoading()
        viewModel.getMeetingsByYearAndMonth(theDate ?? Date())
            .always {
                self.hideLoading()
            }
        .then { (resultDict) in
            self.headerView.eventsByDate = resultDict as? [String: [OOMeetingInfo]]
        }.catch { (myerror) in
            let customError = myerror as! OOAppError
            self.showError(title:  customError.failureReason ?? "")
        }
    }

    func loadtheDayMeetingInfo(_ theDate: Date?) {
        self.showLoading()
        viewModel.getMeetingByTheDay(theDate ?? Date()).always {
            self.hideLoading()
        }.then { (infos) in
            self.viewModel.theMeetingsByDay.removeAll()
            self.viewModel.theMeetingsByDay.append(contentsOf: infos)
            self.tableView.reloadData()
        }.catch { (myerror) in
            let customError = myerror as! OOAppError
            self.showError(title:  customError.failureReason ?? "")
        }
    }

    private func startProcess(processId: String, identity: String) {
        viewModel.startProcess(processId: processId, identity: identity).then { (list) in
            let taskList = list
            DispatchQueue.main.async {
                let taskStoryboard = UIStoryboard(name: "task", bundle: Bundle.main)
                let todoTaskDetailVC = taskStoryboard.instantiateViewController(withIdentifier: "todoTaskDetailVC") as! TodoTaskDetailViewController
                todoTaskDetailVC.todoTask = taskList[0].copyToTodoTask()
                todoTaskDetailVC.backFlag = 3
                self.navigationController?.pushViewController(todoTaskDetailVC, animated: true)
            }
            }.catch { (error) in
                self.showError(title: "启动会议流程出错！")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   

}

// MARK:- EmptyDataSetSource,EmptyDataSetDelegate
extension OOMeetingInforController: EmptyDataSetSource, EmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let text = "您当前还没有会议"
        let titleAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hex: "#CCCCCC"), NSAttributedString.Key.font: UIFont.init(name: "PingFangSC-Regular", size: 18)!]
        return NSMutableAttributedString(string: text, attributes: titleAttributes)
    }


    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "icon_wuhuiyi")
    }

    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor(hex: "#F5F5F5")
    }


    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return true
    }
}

extension OOMeetingInforController: O2BBSCreatorViewDelegate {
    func creatorViewClicked(_ view: O2BBSCreatorView) {
        if let c = self.config, let pId = c.process?.id {
            self.showLoading(title: "Loading")
            viewModel.loadMeetingProcess(processId: pId).then { (list) in
                self.hideLoading()
                if list.count == 1 {
                    self.startProcess(processId: pId, identity: list[0].distinguishedName!)
                } else {
                    var actions: [UIAlertAction] = []
                    list.forEach({ (identity) in
                        let action = UIAlertAction(title: "\(identity.name!)(\(identity.unitName!))", style: .default, handler: { (a) in
                            self.startProcess(processId: pId, identity: identity.distinguishedName!)
                        })
                        actions.append(action)
                    })
                    self.showSheetAction(title: "提示", message: "请选择创建会议流程的身份", actions: actions)
                }
            }.catch { (error) in
                DDLogError("\(error)")
                self.hideLoading()
//                self.performSegue(withIdentifier: "showCreateMeetingSgue", sender: nil)
                self.performSegue(withIdentifier: "showMeetingForm", sender: nil)
            }
        } else {
//            self.performSegue(withIdentifier: "showCreateMeetingSgue", sender: nil)
            self.performSegue(withIdentifier: "showMeetingForm", sender: nil)
        }
    }
}

// MARK:- OOMeetingInforHeaderViewDelegate
extension OOMeetingInforController: OOMeetingInforHeaderViewDelegate {
    func selectedTheDay(_ theDay: Date?) {
        self.currentSelectDay = theDay
        loadtheDayMeetingInfo(theDay)
    }

    func selectedTheMonth(_ theMonth: Date?) {
        self.currentMonthDay = theMonth
        loadCurrentMonthCalendar(theMonth)
    }
}

// MARK:- UITableViewDataSource,UITableViewDelegate
extension OOMeetingInforController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: meetingIdentifier, for: indexPath)
        let uCell = cell as! OOMeetingInforItemCell
        uCell.viewModel = viewModel
        let item = viewModel.nodeForIndexPath(indexPath)
        uCell.config(withItem: item)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerView.calendarManager?.settings.weekModeEnabled == false ? hSectionHeight : sectionHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.nodeForIndexPath(indexPath)
        self.performSegue(withIdentifier: "showMeetingDetail", sender: item)
    }
}
