//
//  HomeViewController.swift
//  Team_India
//
//  Created by Josh Quaid on 3/4/22.
//

import UIKit
import Foundation

class HomeViewController: UIViewController {
    
    // keep track of all focus sessions (Date, Time in hrs:mins:secs tuple )
    // adding one dummy value to test addition of new elements to the array
    var focusSessions: [(date:String, time:(hours:Int, minutes: Int, seconds:Int ))] = [
        (date: "4/14/2022" , time:(hours:1, minutes: 30, seconds: 0))
    ]
    
    // Outlets to communicate with the timer elements on the screen
    @IBOutlet weak var timerDisplay: UILabel!
    @IBOutlet weak var hoursInput: UITextField!
    @IBOutlet weak var minutesInput: UITextField!
    @IBOutlet weak var secondsInput: UITextField!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var timeElapsedOutlet: UIButton!
    @IBOutlet weak var clockOutlet: UILabel!
    
    // the timer running on the screen
    var timer:Timer = Timer()
    // the time for which the timer will be runnning
    var count:Int = 0
    // stores whether the timer is ongoing or not
    var isTimerRunning:Bool = false
    // use this to allow user to set time of focus session
    var timeLeft:Int = 0
    // use this to keep track of the time elapsed so far
    var timeElapsed:Int = 0
    // keep track of the current time on the timer
    var currTime: (Int, Int, Int) = (0, 0, 0)
    // used to store the current date
    let date = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        #warning("remove back button and show Logout in top right")
        // change the color of the start button to green
        startStopButton.setTitleColor(UIColor.green, for: .normal)
        
        // Store the current date in the date variable for formatting below
        let currDate = NSDate()
        let dateFormat = DateFormatter()
        // ensure the time showing is 12 hour time and not 24 hour time
        dateFormat.dateFormat = "hh:mm a"
        // store the corresponding string symbolizing the time in dateString
        let dateString = dateFormat.string(from: date as Date)
        // assing the dateString to the screen outlet element showign the time to the user
        clockOutlet.text = dateString
        
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Actions
    // When the start button is tapped, start a timer with the times provided by the user
    // When the stop button is tapped, change the inputs to the current count so
    // the user is able to resume from current stopping point
    @IBAction func startStopTapped(_ sender: Any) {
        // if the timer is running at the moment and the user tapped on "STOP"
        if isTimerRunning {
            // stop the timer
            timer.invalidate()
            
            // set the text fields to the current timer value equivalent
            hoursInput.text = String(currTime.0)
            minutesInput.text = String(currTime.1)
            secondsInput.text = String(currTime.2)
            
            // Allow the user to change the values in the text fields once more
            hoursInput.isUserInteractionEnabled = true
            minutesInput.isUserInteractionEnabled = true
            secondsInput.isUserInteractionEnabled = true
            
            // reflect the state of the timer in the boolean variable
            isTimerRunning = false
            // change the color back to green
            startStopButton.setTitleColor(UIColor.green, for: .normal)
            // change the text of the button back to START
            startStopButton.setTitle("START", for: .normal)
            
            // Add the current time that has elapsed to the focusSessions array
            
            // store the current date
            let currDate = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .none)
            // conver the time elapsed in seconds to hours:minutes:seconds
            let addTime = convertToHrsMinsSecs(seconds: timeElapsed)
            
            // determine the last index in the array
            var nextIndex = focusSessions.count - 1
            // SET the current completed session to the focusSessions array at most recent date if still
            // the same as today's date, otherwise, create a new entry
            if focusSessions[nextIndex].date == currDate {
                // add the hours elapsed
                focusSessions[nextIndex].time.hours = addTime.0
                // add the minutes elapsed
                focusSessions[nextIndex].time.minutes = addTime.1
                // add the seconds elapsed
                focusSessions[nextIndex].time.seconds = addTime.2
            } else {
                // adding the current session to the end of the array
                focusSessions.append((currDate, addTime))
                nextIndex += 1
            }
            
            // print out statement to confirm time in between completion of focus session has been added
            print("TESTING: Time in between focus sessions has been added to  \(focusSessions[nextIndex].date), the new time stored is  \(focusSessions[nextIndex].time.hours) hours, \(focusSessions[nextIndex].time.minutes) minutes, and \(focusSessions[nextIndex].time.seconds) seconds")
        }
        // if the timer is not running and the user tapped on "START"
        else {
            // change the boolean value to reflect the running timer
            isTimerRunning = true
            // change the text of the button
            startStopButton.setTitle("STOP", for: .normal)
            // change the color of the button to red while timer is running
            startStopButton.setTitleColor(UIColor.red, for: .normal)
            // Keep the user from being able to change the text field balues while the timer is running
            hoursInput.isUserInteractionEnabled = false
            minutesInput.isUserInteractionEnabled = false
            secondsInput.isUserInteractionEnabled = false
            
            // reset the contents of the count variable whenever the start
            // button is clicked
            count = 0
            
            // Ensure all user input fields have a default value to them
            var hours = hoursInput.text
            var minutes = minutesInput.text
            var seconds = secondsInput.text
            // check for empty text field
            if hours == "" {
                hours = "0"
                hoursInput.text = "0"
            }
            // set a default value of 30 if this text field is empty
            if minutes == "" {
                minutes = "30"
                minutesInput.text = "0"
            }
            // check for empty text field
            if seconds == "" {
                seconds = ""
                secondsInput.text = "0"
            }
            
            // conver the user inputs to their corresopnding time values
            count += Int(hours!)! * 3600
            count += Int(minutes!)! * 60
            count += Int(seconds!)!
            
            // update the timer
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timeCounter), userInfo: nil, repeats: true)
        }
    }
    
    // Resets the current timer back to 0 when the reset button is tapped
    @IBAction func resetTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Reset Timer?", message: "Are you sure you want to reset the timer?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            // do nothing
        }))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            self.count = 0
            self.timer.invalidate()
            // set the current text in the label to all zeroes
            self.timerDisplay.text = self.convertTimeToString(hours: 0, minutes: 0, seconds: 0)
            // change the color back to green
            self.startStopButton.setTitleColor(UIColor.green, for: .normal)
            // change the text of the button back to START
            self.startStopButton.setTitle("START", for: .normal)
            
            // allow the user to change the values of the text fields once more
            self.hoursInput.isUserInteractionEnabled = true
            self.minutesInput.isUserInteractionEnabled = true
            self.secondsInput.isUserInteractionEnabled = true
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // register the user's time input from the text fields on screen
    @IBAction func userTimeInput(_ sender: Any) {
        // ensure the current input text field have default values
        let hours: String = hoursInput.text ?? "0"
        let minutes: String = minutesInput.text ?? "30"
        let seconds: String = secondsInput.text ?? "0"
        
        // reset the value of the counter if new input is registered
        count = 0
        
        // check if input can be converted to an int
        // conver the integer to the huor equivalent in seconds
        if let hrs = Int(hours) { count += hrs * 3600 }
        if let mins = Int(minutes) { count += mins * 60 }
        if let secs = Int(seconds) { count += secs }
    }
    
    // updates the timer and the time elepased fields every seconds
    @objc func timeCounter() -> Void {
        count = count - 1
        timeElapsed += 1
        // pass the count value to the function to break up into time displayed
        currTime = convertToHrsMinsSecs(seconds: count)
        let currTimeString = convertTimeToString(hours: currTime.0, minutes: currTime.1, seconds: currTime.2)
        timerDisplay.text = currTimeString
        
        // update the time elapsed field
        let elapsedAdd = convertToHrsMinsSecs(seconds: timeElapsed)
        let elapsedAddString = convertTimeToString(hours: elapsedAdd.0, minutes: elapsedAdd.1, seconds: elapsedAdd.2)
        timeElapsedOutlet.setTitle(elapsedAddString, for: .normal)
        
        // check if the timer is done
        if count <= 0 {
            // stop the timer when it gets to zero
            timer.invalidate()
            // change the button back to start
            self.startStopButton.setTitle("STOP", for: .normal)
            // allow the user to change the values of the text fields since the timer is done
            hoursInput.isUserInteractionEnabled = true
            minutesInput.isUserInteractionEnabled = true
            secondsInput.isUserInteractionEnabled = true
            
            // send an alert to the user
            let alert = UIAlertController(title: "Focus session finished", message: "Time to take a break!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
                // do nothing
            }))
            self.present(alert, animated: true, completion: nil)
            
            // store the current date
            let currDate = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .none)
            
            // conver the time elapsed in seconds to hours:minutes:seconds
            let addTime = convertToHrsMinsSecs(seconds: timeElapsed)
            
            // determine the last index in the array
            var nextIndex = focusSessions.count - 1
            // add the current completed session to the focusSessions array at most recent date if still
            // the same as today's date, otherwise, create a new entry
            if focusSessions[nextIndex].date == currDate {
                // add the hours elapsed
                focusSessions[nextIndex].time.hours += addTime.0
                // add the minutes elapsed
                focusSessions[nextIndex].time.minutes += addTime.1
                // add the seconds elapsed
                focusSessions[nextIndex].time.seconds += addTime.2
            } else {
                // adding the current session to the end of the array
                focusSessions.append((currDate, addTime))
                nextIndex += 1
            }
            
            // showing how to print out the focus sessions on the screen
            print("TESTING: The current focus session has been logged on day \(focusSessions[nextIndex].date.split(separator: "/")[1]) of month \(focusSessions[nextIndex].date.split(separator: "/")[nextIndex]) for for a total of \(focusSessions[nextIndex].time.hours) hours, \(focusSessions[nextIndex].time.minutes) minutes, and \(focusSessions[nextIndex].time.seconds) seconds")
        }
        
        // Store the current date in the date variable for formatting below
        _ = NSDate()
        let dateFormat = DateFormatter()
        // ensure the time showing is 12 hour time and not 24 hour time
        dateFormat.dateFormat = "hh:mm a"
        // store the corresponding string symbolizing the time in dateString
        let dateString = dateFormat.string(from: date as Date)
        // assing the dateString to the screen outlet element showign the time to the user
        clockOutlet.text = dateString
    }
    
    // convert total secons into hours, minutes, and seconds tuple
    func convertToHrsMinsSecs(seconds: Int) -> (Int, Int, Int) {
        return ((seconds / 3600), ((seconds % 3600)/60), ((seconds % 3600)%60))
    }
    
    // convert the hours, minutes and seconds generated by the previous function into a string
    // to display for the user
    func convertTimeToString(hours: Int, minutes:Int, seconds:Int) -> String {
        // holds the final result of the time conversion
        var answer = ""
        answer += String(format: "0%2d", hours)
        answer += " : "
        answer += String(format: "0%2d", minutes)
        answer += " : "
        answer += String(format: "0%2d", seconds)
        // return the final string to display for the user
        return answer
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
