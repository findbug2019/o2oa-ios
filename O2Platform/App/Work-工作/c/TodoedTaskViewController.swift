//
//  TodoedTaskViewController.swift
//  O2Platform
//
//  Created by 刘振兴 on 16/8/15.
//  Copyright © 2016年 zoneland. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import AlamofireObjectMapper

import ObjectMapper

import CocoaLumberjack

class TodoedTaskViewController: UITableViewController {

    
    var loadUrl:String?
    
    var todoedActions:[TodoedActionModel] = []
    
    var todoedStatus:[TodoedStatusModel] = []
    
    var todoTask:TodoTaskData? {
        didSet {
            let url = AppDelegate.o2Collect.generateURLWithAppContextKey(TaskedContext.taskedContextKey, query: TaskedContext.taskedDataByIdQuery, parameter: ["##id##":(todoTask?.id)! as AnyObject])
            self.loadUrl = url
        }
    }
    
    private lazy var viewModel: WorkViewModel = {
        return WorkViewModel()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var t = self.todoTask?.title
        if t == nil || t?.isEmpty == true {
            t = self.todoTask?.processName ?? ""
        }
        title = t
        self.loadTodoedData()
    }
    
    func loadTodoedData(){
        if let id = self.todoTask?.id {
            self.showLoading(title: "加载中...")
            self.viewModel.getReferenc(id: id).then { (reference) in
                let workList = reference.workList
                let workcompletedList = reference.workCompletedList
                if workList.count > 0 {
                    self.setActionModel(workList,completed: false)
                }else if workcompletedList.count > 0 {
                    self.setActionModel(workcompletedList,completed: true)
                }
                let worklogList = reference.workLogList
                self.setStatusModel(worklogList)
                self.tableView.reloadData()
            }.always {
                self.hideLoading()
            }.catch { (err) in
                DDLogError(err.localizedDescription)
                self.showError(title: "加载失败")
            }
        }
        
        
        
//        AF.request(loadUrl!).responseJSON(completionHandler:{  response in
//            debugPrint(response.result)
//            switch response.result {
//            case .success(let val):
//                let data = JSON(val)["data"]
//                let type = JSON(val)["type"]
//                DDLogDebug(data.description)
//                if type == "success" {
//                    self.setActionModel(data["taskCompleted"].array,completed: true)
//                    self.setActionModel(data["workCompletedList"].array, completed: true)
//                    self.setActionModel(data["workList"].array,completed: false)
//                    self.setStatusModel(Mapper<ActivityTask>().mapArray(JSONString:data["workLogList"].description))
//                    self.tableView.reloadData()
//                    self.showSuccess(title: "加载完成")
//                }else{
//                    DDLogError(JSON(val)["message"].description)
//                    self.showError(title: "加载失败")
//                }
//            case .failure(let err):
//                DDLogError(err.localizedDescription)
//                self.showError(title: "加载失败")
//            }
//        })
    }
    
    func setActionModel(_ actionArray:[WorkData],completed:Bool){
        for action  in actionArray {
            if completed {
                let title = "\(action.title ?? "") 完成于\(action.completedTime ?? "")"
                let id = action.id
                let workType = "workCompletedList"
                var workTitle = ""
                let wtitle = action.title ?? ""
                let pName = action.processName ?? ""
                if !wtitle.trim().isEmpty {
                    workTitle = wtitle
                }else if !pName.trim().isEmpty {
                    workTitle = pName
                }
                let actionModel = TodoedActionModel(destText: title, workType: workType, workId: id, workTitle: workTitle)
                self.todoedActions.append(actionModel)
            }else{
                let title = "\(action.title ?? "") 当前在\(action.activityName ?? "")"
                let id = action.id
                let workType = "workList"
                var workTitle = ""
                let wtitle = action.title ?? ""
                let pName = action.processName ?? ""
                if !wtitle.trim().isEmpty {
                    workTitle = wtitle
                }else if !pName.trim().isEmpty {
                    workTitle = pName
                }
                let actionModel = TodoedActionModel(destText: title, workType: workType, workId: id, workTitle: workTitle)
                self.todoedActions.append(actionModel)
            }
            
        }
    }
    
    func setStatusModel(_ statusArray:[ActivityTaskData]){
        for task in statusArray {
            if task.fromActivityType == "begin" {
                continue
            }
            if (task.taskCompletedList == nil || task.taskCompletedList!.count == 0) && (task.taskList == nil || task.taskList!.count == 0) {
                continue
            }
            // 计算任务数
            var identities: [String] = []
            if (task.taskCompletedList ==  nil || task.taskCompletedList!.count == 0) {
                if (task.taskList!.count > 0 ) {
                    task.taskList?.forEach({ (data) in
                        if let id = data.identity {
                            identities.append(id)
                        }
                    })
                }
            }else{
//                identity = (task.taskCompletedList![0] as! NSDictionary)["identity"]! as! String;
                task.taskCompletedList?.forEach({ (data) in
                    if let id = (data as? NSDictionary)?["identity"] as? String {
                        identities.append(id)
                    }
                })
            }
            if identities.count > 0 {
                for item in identities {
                    let activity = task.arrivedActivityName == nil ? task.fromActivityName : "\(task.fromActivityName ?? "") -> \(task.arrivedActivityName ?? "")"
                    let status = task.routeName == nil ? "正在处理":"选择了【\(task.routeName ?? "")】"
                    let time = task.arrivedTime == nil ? "到达于：\(task.fromTime ?? "")" : "提交于：\(task.arrivedTime ?? "")"
                    let identity = item.components(separatedBy: "@").first ?? ""
                    let statusModel = TodoedStatusModel(activity: activity, identity: identity, status: status, statusTime: time)
                    self.todoedStatus.append(statusModel)
                }
            }
            
        }
     
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch  section {
        case 0:
            return self.todoedActions.count
        case 1:
            return self.todoedStatus.count
        default:
            return 0
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "todoedActionCell", for: indexPath) as! TodoedActionCell
            cell.delegate = self
            cell.actionModel = self.todoedActions[(indexPath as NSIndexPath).row]
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "todoedStatusCell", for: indexPath) as! TodoedStatusCell
            cell.statusModel = self.todoedStatus[(indexPath as NSIndexPath).row]
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "none")
        }
       
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 1{
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        
            //设置动画时间为0.25秒,xy方向缩放的最终值为1
        
            UIView.animate(withDuration: 0.25 * (Double((indexPath as NSIndexPath).row) + 1.0), animations: { () -> Void in
            
                cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
            
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath as NSIndexPath).section {
        case 0:
            return 60.0
        case 1:
            return 100.0
        default:
            return 44.0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "showTodoedWork" {
            let destVC = segue.destination as! TodoTaskDetailViewController
            if let model =  sender as? TodoedActionModel {
                let id = model.workId ?? ""
                let title = model.workTitle ?? ""
                let json: String
                if model.workType == "workCompletedList" {
                    json = """
                    {"workCompleted":"\(id)", "title":"\(title)"}
                    """
                }else {
                    json = """
                    {"work":"\(id)", "title":"\(title)"}
                    """
                }
                let todo = TodoTask(JSONString: json)
                destVC.todoTask = todo
            }
            destVC.backFlag = 4 // 特殊来源
        }
    }
    

}

extension TodoedTaskViewController:TodoedActionCellDelegate{
    func open(_ actionModel: TodoedActionModel) {
        DDLogDebug(actionModel.workId!)
        self.performSegue(withIdentifier: "showTodoedWork", sender: actionModel)
        
    }
}
