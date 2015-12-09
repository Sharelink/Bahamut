//
//  SoundService.swift
//  Bahamut
//
//  Created by AlexChow on 15/10/29.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import Foundation
import CoreLocation

class LocationService:NSNotificationCenter,ServiceProtocol,CLLocationManagerDelegate
{
    @objc static var ServiceName:String{return "LocationService"}
    static let hereUpdated = "hereUpdated"
    private var locationManager:CLLocationManager!
    @objc func appStartInit() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 700.0
        self.locationManager.startUpdatingLocation()
    }
    
    func userLoginInit(userId: String) {
        self.setServiceReady()
    }
    
    var isLocationServiceEnabled:Bool{
        return CLLocationManager.locationServicesEnabled()
    }
    
    func refreshHere()
    {
        self.locationManager.startUpdatingLocation()
    }
    
    private(set) var here:CLLocation!
    
    //MARK: CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        here = newLocation
        self.postNotificationName(LocationService.hereUpdated, object: self)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
    }
}