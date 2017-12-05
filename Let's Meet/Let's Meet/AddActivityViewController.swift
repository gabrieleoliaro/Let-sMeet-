//
//  AddActivityViewController.swift
//  Let's Meet
//
//  Created by Gabriele Oliaro on 12/5/17.
//  Copyright © 2017 Kit, Alejandro & Gabriel. All rights reserved.
//

import UIKit
import os.log

class AddActivityViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var activityNamePicker: UIPickerView!
    @IBOutlet weak var activityNameLabel: UITextField!
    @IBOutlet weak var activityDescriptionLabel: UITextField!
    @IBOutlet weak var activityLocationLabel: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var recent_activities: [String]?


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Handle the text field's user input through delegate callbacks.
        activityNameLabel.delegate = self
        activityDescriptionLabel.delegate = self
        activityLocationLabel.delegate = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Hide the keyboard
        textField.resignFirstResponder()
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        return true
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(CGPoint(x: 0, y: 175), animated: true)
    }
    
    
    //MARK: Picker Delegate and Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return recent_activities!.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == recent_activities!.count
        {
            return "New activity..."
        }
        else
        {
            return recent_activities![row]
        }
        
    }

    
    // MARK: - Navigation

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        super.prepare(for: segue, sender: sender)
        
        
        //#cs50 There is actually only one segue, so the code would work evern without the switch, but it's safer to include it in case a new segue is added in the future.
        switch(segue.identifier ?? "") {
            
        case "goto_part2":
            
            guard let AddActivityViewController2 = segue.destination as? AddActivityViewController2 else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            //if UIPickerView.
            
            //let parameters: [String: String] = [""]
            //AddActivityViewController2.
            //let selectedActivity = activities[indexPath.row]
            //activityDetailedViewController.activity = selectedActivity
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
            
        }
    }
    

}
