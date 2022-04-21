//
//  DetailViewController.swift
//  Team_India
//
//  Created by Josh Quaid on 3/4/22.
//

import UIKit
import Firebase
import Charts
import SwiftUI
import Foundation

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    // The outlet for the position of the graph view
    @IBOutlet weak var graphViewPlaceholder: UIImageView!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    
    // The outlets to select the bar type
    @IBOutlet weak var selectBarButton: UIButton!
    @IBOutlet weak var selectLineButton: UIButton!
    
    // Table view
    @IBOutlet weak var StatsTableview: UITableView!
    
    
    // Date outlets
    @IBOutlet weak var ennddate: UIDatePicker!
    @IBOutlet weak var startdate: UIDatePicker!
    
    
    struct Session {
            let date: Date
            let workingOn: String
            let time: (hours: Int, minutes: Int, seconds: Int)
        }
    
    private var focusSessions: [Session] = []
    private var currentSessions: [Session] = []
    private var currentDict: [Date: [Session]] = [:]
    
    // Array of focusSession tuples for graph display
    //private var focusSessions: [(date: String, workingOn: String, time:(hours: Int, minutes: Int, seconds: Int ))] = []
    
    // The vars needed to create graphs
    lazy var barGraph: BarChartView = {
        let barChart = ChartMaker.makeBarChart()
        barChart.data = setBarGraphData(fromDate: startDatePicker.date, toDate: startDatePicker.date)
 
        return barChart
    }()
    
    lazy var lineGraph: LineChartView = {
        let lineChart = ChartMaker.makeLineChart()
        return lineChart
    }()
    
    // MARK: - View Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Set the color of the logout button to white for visibility
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
        // date picker
        startdate.datePickerMode = .date
                startdate.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
                ennddate.datePickerMode = .date
                ennddate.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)

        // Get the data from Firestore
        self.getFirestoreData()
        self.filter()
        
        
        // table view
        view.addSubview(StatsTableview)
        StatsTableview.delegate = self
        StatsTableview.dataSource = self
        
        
        // Show the bar graph as the default graph
        
        self.barGraph.rightAxis.enabled = false
        self.barGraph.frame = self.graphViewPlaceholder.frame
        self.view.addSubview(self.barGraph)
        
        


    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        
    }
    
    // Getting the dates when we change
    @objc func dateChanged(_ sender: UIDatePicker) {
        self.filter()
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
    // filter function
    func filter(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let selectedDate = dateFormatter.string(from: startdate.date)
        let date1 = dateFormatter.date(from: selectedDate)
        let selectedDate2 = dateFormatter.string(from: ennddate.date)
        let date2 = dateFormatter.date(from: selectedDate2)
       
        
        let resultarray = focusSessions.filter { $0.date >= date1! && $0.date <= date2!}
        self.currentSessions = resultarray
        var dict: [Date: [Session]] = [:]
        for i in currentSessions {
            let keys = dict.keys
            if keys.contains(i.date) {
                dict[i.date]?.append(i)
            } else {
                dict[i.date] = [i]
            }
        }
        self.currentDict = dict
        self.StatsTableview.reloadData()
        self.barGraph.data = setBarGraphData(fromDate: startDatePicker.date, toDate: ennddate.date)
        self.barGraph.notifyDataSetChanged()

        
        for (key, value) in currentDict {
            print("day is \(key)")
            for session in value {
                print(session)
            }
        }
        
        }

    // MARK: - Handlers
    
    @IBAction func barTypeButtonHandler(_ sender: UIButton) {
        
        // Handle the button taps to select a graph type
        switch sender {
        case selectBarButton:
            // Show the bar graph
            DispatchQueue.main.async {
                // Remove the lineGraph from the view
                self.lineGraph.removeFromSuperview()
                // Add the barGraph to the view
                self.view.addSubview(self.barGraph)
                self.barGraph.rightAxis.enabled = false
                self.barGraph.frame = self.barGraph.frame
                // Reanimate the graph
                self.barGraph.animate(xAxisDuration: 2.5)
            }
        case selectLineButton:
            // Show the line graph
            DispatchQueue.main.async {
                // Remove the barGraph from the view
                self.barGraph.removeFromSuperview()
                // Add the lineGraph to the view
                self.view.addSubview(self.lineGraph)
                self.lineGraph.rightAxis.enabled = false
                self.lineGraph.frame = self.barGraph.frame
                // Reanimate the graph
                self.lineGraph.animate(xAxisDuration: 2.5)
            }
        default:
            // Do nothing
            return
        }
        
    }
    
    
    
    // MARK: - Funcs
    
    // Gets the user's focusSession from the Firestore DB
    private func getFirestoreData() {        
        // Get a reference to the Firestore DB
        let firestoreDB = Firestore.firestore()
        // Get the currently signed in user
        let user = Auth.auth().currentUser
        
        // make sure the user is signed in before trying to access the user information and store to the DB
        if let user = user {
            // Write the focusSession to Firestore
            // Get the collection of focusSessions from the Firestore DB, then populate the focusSessions array for graph display
            firestoreDB.collection("users").document(user.uid).collection("focusSessions").getDocuments { dbCollection, error in
                // Check if any errors in get
                if error == nil {
                    // unwrap the dbCollectioon returned from Firestore and append each session to the focusSession array
                    if let dbCollection = dbCollection {
                        // Put this in the main queue since it's UI related
                        DispatchQueue.main.async {
                            // Populate the array from the document collection
                            for session in dbCollection.documents {
                                let dateString = session.get("date")
                                let dateFormatter = DateFormatter()
                                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                                dateFormatter.dateFormat = "MM/dd/yyyy"
                                if let date = dateFormatter.date(from: dateString as! String) {
                                                                  
                                    self.focusSessions.append(Session(date: date, workingOn: session.get("workingOn") as! String, time: (hours: session.get("timeHours") as! Int, minutes: session.get("timeMinutes") as! Int, seconds: session.get("timeSeconds") as! Int)))
                                    }
                                //                                    self.focusSessions.append((date: date , workingOn: session.get("workingOn") as! String, time: (hours: session.get("timeHours") as! Int, minutes: session.get("timeMinutes") as! Int, seconds: session.get("timeSeconds") as! Int)))

                            }
                            self.filter()
                            self.StatsTableview.reloadData()
                        }
                    }
                } else {
                    // Deal with the error
                    print("Error retrieving focusSession: \(String(describing: error))")
                }
            }
        } else {
            print("user is not signed in")
        }

    
    }

    // Shows error messages in an AlertController
    func showErrorMessage(message : String) {
        // Show an AlertController
        let alertController = UIAlertController(title: "Error Registering User",
                                          message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        // Add the action to the alertController
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }
    
    func setBarGraphData(fromDate: Date, toDate: Date) -> BarChartData {
        // Get the number of days to display. Pass the from and to date to Calendar, grab the number of days
        //      from the result, then add 1 since we always want to include the start date.
        let numDays = (Calendar.current.dateComponents([.day], from: fromDate, to: toDate).day!) + 1
        print(numDays)
        
        
        
        var entries: [[BarChartDataEntry]] = [[BarChartDataEntry]]()
        
        var dailySessionTimes: [[Double]] = [[Double]]()
        
        var dailySessionIndex = 0
        for (key, session) in currentDict {
            for sessionNumber in session {
                if dailySessionIndex > dailySessionTimes.count - 1 {
                    dailySessionTimes.append([Double]())
                }
                dailySessionTimes[dailySessionIndex].append(Double(sessionNumber.time.hours))
            }
            dailySessionIndex += 1
        }
        
        
        for i in 0..<currentDict.keys.count {
            if i > entries.count - 1 {
                entries.append([BarChartDataEntry]())
            }
            entries[i].append(BarChartDataEntry(x: Double(i), yValues: dailySessionTimes[i]))
        }
        
        
        var dataSets = [BarChartDataSet]()
        
        var labels: [String] = [String]()

        #warning("need this fixed to convert date to string and store in this labels array")
        for key in currentDict.keys {
            //labels.append(key)
        }
        
        // Initialize the dataSets array with the needed number of BarCharDataSets
        for i in 0..<entries.count {
            dataSets.append(BarChartDataSet())
            dataSets[i] = BarChartDataSet(entries: entries[i], label: "Session \(i)")
            dataSets[i].colors = [.systemMint, .green, .blue, .yellow, .cyan, .magenta, .purple, .red]
        }
        
        /* For testing
        for i in 0..<entries.count {
            for j in 0..<entries[i].count {
                print("session number \(j) in day \(i)")
                print(entries[i][j])
            }
        }
         */
        
        let data = BarChartData(dataSets: dataSets)
        
        return data
    }
    
    
    // Sets the color of each individual session in the bar chart (the bar sections)
    func setBarColor(sessionNumber: Int) -> UIColor {
        switch sessionNumber {
        case 0:
            return UIColor.blue
        case 1:
            return UIColor.orange
        case 2:
            return UIColor.green
        case 3:
            return UIColor.cyan
        case 4:
            return UIColor.yellow
        case 5:
            return UIColor.magenta
        case 6:
            return UIColor.green
        case 7:
            return UIColor.blue
        case 8:
            return UIColor.orange
        case 9:
            return UIColor.green
        case 10:
            return UIColor.cyan
        case 11:
            return UIColor.yellow
        case 12:
            return UIColor.magenta
        case 13:
            return UIColor.green
        default:
            return UIColor.magenta
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Stats Tableview functions
        
        
        
        func numberOfSections(in tableView: UITableView) -> Int {
            return currentDict.keys.count
        }
        
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let dates = Array(currentDict.keys)
            let dateformatter = DateFormatter()
            dateformatter.dateFormat = "MM/dd/yyyy"
            let title = dateformatter.string(from: dates[section])
            return title
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let keys = Array(currentDict.keys)
            let sec = keys[section]
            let totalCount = currentDict[sec]?.count
            return totalCount!
        }
        
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath)
            
            let sec = Array(currentDict.keys)[indexPath.section]
            let cellData = currentDict[sec]![indexPath.row]
            //configure cell
            
            cell.textLabel?.text = cellData.workingOn
            cell.textLabel?.font = .systemFont(ofSize: 15)
            cell.detailTextLabel?.font = .systemFont(ofSize: 10)
            let timeHours = cellData.time.hours, timeMinutes = cellData.time.minutes, timeSeconds = cellData.time.seconds
            cell.detailTextLabel?.text = "Worked for \(timeHours) hours, \(timeMinutes) minutes and \(timeSeconds) seconds"
            
            return cell
            
        }


}
