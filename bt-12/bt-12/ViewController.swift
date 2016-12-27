//
//  ViewController.swift
//  bt-12
//
//  Created by Unima-TD-04 on 12/27/16.
//  Copyright © 2016 Unima-TD-04. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController {


    @IBOutlet weak var tableView: UITableView!

    var download = DownloadImage(maxConcurrent: 10)
    var array = [Videos]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let getContext = appDelegate.persistentContainer.viewContext
        do{
            array = try getContext.fetch(Videos.fetchRequest())
        } catch { }
        
        if array.count == 0 {
            getData(modifiedS: "0")
        }else {
            let arrSort = array.sorted(by: {$0.0.modified! > $0.1.modified!})
            let modifiedMax = arrSort[0].modified
            let es = modifiedMax?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            getData(modifiedS: es!)
        }
        
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    
    
    // MARK: get Data
    func getData(modifiedS: String) {
        
        let urlString = "http://nikmesoft.com/apis/englishvideos-api/public/index_debug.php/v1/videos?last_updated=\(modifiedS)"
        guard let url = NSURL(string: urlString) else {
            print("Error url")
            return
        }
        
        let urlRequest = URLRequest(url: url as URL )
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let getContext = appDelegate.persistentContainer.viewContext
        let fetchRequest2: NSFetchRequest<Videos> = Videos.fetchRequest()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Videos")
        
        session.dataTask(with: urlRequest, completionHandler: {(data, response, error) -> Void in
            if error != nil {
                return
            }
            do {
                guard let jsonObj = try? JSONSerialization.jsonObject(with: data!) as! [String : AnyObject] else {
                    return
                }
                
                let arr = jsonObj["videos"] as! [AnyObject]
                for json in arr {
                    let video = Videos(context: getContext)
                    let id = json["id"] as! Int16
                    let name = json["name"] as! String
                    let category_id = json["category_id"] as! Int16
                    let thumbnail = json["thumbnail"] as! String
                    let link = json["link"] as! String
                    let duration = json["duration"] as! Int16
                    let number_of_views = json["number_of_views"] as! Int16
                    let deleted = json["deleted"] as! Int16
                    let created = json["created"] as! String
                    let modified = json["modified"] as! String
                    
                    
                    let predicate = NSPredicate(format: "id == %@", "\(id)")
                    fetchRequest.predicate = predicate
                    
                    let fetched = try getContext.fetch(fetchRequest) as! [Videos]
                    if fetched.count == 0 {
                        video.id = id
                        video.name = name
                        video.category_id = category_id
                        video.thumbnail = thumbnail
                        video.link = link
                        video.duration = duration
                        video.number_of_view = number_of_views
                        video.delete = deleted
                        video.created = created
                        video.modified = modified
                    } else {
                        fetched.first?.name = name
                        fetched.first?.category_id = category_id
                        fetched.first?.thumbnail = thumbnail
                        fetched.first?.link = link
                        fetched.first?.duration = duration
                        fetched.first?.number_of_view = number_of_views
                        fetched.first?.delete = deleted
                        fetched.first?.created = created
                        fetched.first?.modified = modified
                    }
                }
                
                OperationQueue.main.addOperation {
                    self.tableView.reloadData()
                }
                
            } catch {
                print("error trying to convert data to JSON")
                return
            }
            
            do {
                try getContext.save()
            } catch {
                print("miss data")
            }
        }).resume()
        
        let sortD = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest2.sortDescriptors = [sortD]
        do {
            self.array = try getContext.fetch(fetchRequest2)
        }catch{}
        
    }
    
    // MARK: Delete All Data
    func deleteAllData(entity: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let getContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try getContext.fetch(fetchRequest)
            for managedObject in results {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                getContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
    
    
}

// MARK: Table View Data Source

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(array.count)
        return array.count
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = Bundle.main.loadNibNamed("TableViewCell", owner: self, options: nil)?.first as! TableViewCell
        
        cell.nameCell.text = array[indexPath.row].name
        cell.personViewCell.text = "\(array[indexPath.row].number_of_view)"
        download.downloadJsonWithTask(url: array[indexPath.row].thumbnail!, indexPath: indexPath, callBack: { (returnIndexpath, image) -> Void in
            if indexPath == returnIndexpath {
                cell.imageCell.image = image
            }
        })
        return cell
    }
    
}
