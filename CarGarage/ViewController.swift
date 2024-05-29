//
//  ViewController.swift
//  CarGarage
//
//  Created by Andrei Harnashevich on 29.05.24.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    // MARK: - Variables
    
    var context: NSManagedObjectContext!
    var car: Car!
    
    lazy private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    // MARK: - UI
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentControl()
            segmentedControl.selectedSegmentTintColor = .white
            let whiteTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttributes, for: .selected)
        }
    }
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getDataFromFile()
    }
    
    // MARK: - Actions
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car.timesDriven += 1
        car.lastStarted = Date()
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Rate it",
            message: "Rate this car, please",
            preferredStyle: .alert
        )
        
        let rateAction = UIAlertAction(
            title: "Rate",
            style: .default
        ) { action in
            if let text = alertController.textFields?.first?.text {
                self.update(rating: (text as NSString).doubleValue)
            }
        }
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .default
        )
        
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

// MARK: - Methods

extension ViewController {
    
    private func updateSegmentControl() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark ?? String())
        
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first ?? Car()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func update(rating: Double) {
        car.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car)
        } catch let error as NSError {
            let alertController = UIAlertController(
                title: "Wrong value",
                message: "Wrond input",
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(
                title: "Ok",
                style: .default
            )
            
            alertController.addAction(okAction)
            present(alertController, animated: true)
            print(error.localizedDescription)
        }
    }
    
    private func insertDataFrom(selectedCar car: Car) {
        carImageView.image = UIImage(data: car.imageData ?? Data())
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !car.myChoice
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Numbers of trips: \(car.timesDriven)"
        lastTimeStartedLabel.text = "Last time started: \(dateFormatter.string(from: car.lastStarted ?? Date()))"
        segmentedControl.backgroundColor = car.tinColor as? UIColor
    }
    
    private func getDataFromFile() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
            print("Is Data there already")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        guard records == 0 else { return }
        
        guard
            let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"),
            let dataArray = NSArray(contentsOfFile: pathToFile)
        else {
            return
        }
        
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            
            let carDictionary = dictionary as! [String: AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoice = carDictionary["myChoice"] as! Bool
            
            let imageName = carDictionary["imageName"] as? String
            let image = UIImage(named: imageName ?? String())
            let imageData = image?.pngData()
            car.imageData = imageData
            
            if let colorDictionary = carDictionary["tintColor"] as? [String: Float] {
                car.tinColor = getColor(colorDictionary: colorDictionary)
            }
        }
    }
    
    private func getColor(colorDictionary: [String: Float]) -> UIColor {
        guard
            let red = colorDictionary["red"],
            let green = colorDictionary["green"],
            let blue = colorDictionary["blue"]
        else {
            return UIColor()
        }
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1)
    }
}
