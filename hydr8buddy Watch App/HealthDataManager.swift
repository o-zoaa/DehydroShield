//
//  HealthDataManager.swift
//  hydr8buddy
//
//  Created by Omar Abdulaziz on 2/14/25.
//

import Foundation
import HealthKit
import SwiftUI

/// Manages HealthKit operations for heart rate, HRV, steps, active energy, exercise time, distance, and body temperature.
class HealthDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var heartRate: Double?            // BPM
    @Published var heartRateVariability: Double?   // HRV (SDNN) in ms
    @Published var stepCount: Double?              // Steps today
    @Published var activeEnergy: Double?           // Active energy (kcal) today
    @Published var exerciseTime: Double?           // Apple Exercise Time (minutes) today
    @Published var distance: Double?               // Distance walked/ran (meters) today
    @Published var bodyTemperature: Double?        // Body temperature in Celsius
    
    private var isObservingHeartRate = false
    private var isObservingHRV = false
    private var isObservingSteps = false
    private var isObservingActiveEnergy = false
    private var isObservingExerciseTime = false
    private var isObservingDistance = false
    private var isObservingBodyTemperature = false
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            return
        }
        
        guard
            let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
            let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount),
            let aeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
            let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature)
        else {
            print("One or more HealthKit types are unavailable.")
            return
        }
        
        let toRead: Set<HKObjectType> = [hrType, hrvType, stepsType, aeType, exerciseTimeType, distanceType, temperatureType]
        
        healthStore.requestAuthorization(toShare: [], read: toRead) { [weak self] success, error in
            if let error = error {
                print("Authorization failed: \(error.localizedDescription)")
                return
            }
            guard let self = self else { return }
            
            if success {
                // Delay fetching by 1 second to allow authorization state to settle.
                DispatchQueue.main.async {
                    self.fetchLatestHeartRate()
                    self.fetchLatestHRV()
                    self.fetchDailySteps()
                    self.fetchActiveEnergyBurned()
                    self.fetchExerciseTime()
                    self.fetchDailyDistance()
                    self.fetchLatestBodyTemperature()
                    
                    self.startObservingHeartRate()
                    self.startObservingHRV()
                    self.startObservingSteps()
                    self.startObservingActiveEnergy()
                    self.startObservingExerciseTime()
                    self.startObservingDistance()
                    self.startObservingBodyTemperature()
                }
            } else {
                print("Authorization not granted.")
            }
        }
    }
    
    // MARK: - Manual Data Refresh
    func refreshData() {
        fetchLatestHeartRate()
        fetchLatestHRV()
        fetchDailySteps()
        fetchActiveEnergyBurned()
        fetchExerciseTime()
        fetchDailyDistance()
        fetchLatestBodyTemperature()
    }
    
    // MARK: - Heart Rate
    private func startObservingHeartRate() {
        guard !isObservingHeartRate else { return }
        isObservingHeartRate = true
        
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let query = HKObserverQuery(sampleType: hrType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Heart Rate Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchLatestHeartRate()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: hrType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (HR) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for HR: \(success)")
            }
        }
    }
    
    func fetchLatestHeartRate() {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { [weak self] _, samples, error in
            if let error = error {
                print("Fetch HR error: \(error.localizedDescription)")
                return
            }
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No HR samples found.")
                return
            }
            let unit = HKUnit.count().unitDivided(by: .minute())
            let bpmValue = sample.quantity.doubleValue(for: unit)
            DispatchQueue.main.async {
                self?.heartRate = bpmValue
                print("fetchLatestHeartRate() - New HR: \(bpmValue)")
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - HRV
    private func startObservingHRV() {
        guard !isObservingHRV else { return }
        isObservingHRV = true
        
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("HRV Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchLatestHRV()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (HRV) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for HRV: \(success)")
            }
        }
    }
    
    func fetchLatestHRV() {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { [weak self] _, samples, error in
            if let error = error {
                print("Fetch HRV error: \(error.localizedDescription)")
                return
            }
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No HRV samples found.")
                return
            }
            let msValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            DispatchQueue.main.async {
                self?.heartRateVariability = msValue
                print("fetchLatestHRV() - New HRV: \(msValue) ms")
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Steps
    private func startObservingSteps() {
        guard !isObservingSteps else { return }
        isObservingSteps = true
        
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let query = HKObserverQuery(sampleType: stepsType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Steps Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchDailySteps()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepsType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (Steps) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for Steps: \(success)")
            }
        }
    }
    
    func fetchDailySteps() {
        guard let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let cal = Calendar.current
        guard let startDay = cal.date(bySettingHour: 0, minute: 0, second: 0, of: now) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: now, options: .strictStartDate)
        let statsQuery = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, error in
            if let error = error {
                print("Fetch Steps error: \(error.localizedDescription)")
                return
            }
            guard let stats = stats, let sumQ = stats.sumQuantity() else {
                print("No step data found.")
                return
            }
            let stepVal = sumQ.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                self?.stepCount = stepVal
                print("fetchDailySteps() - Steps: \(stepVal)")
            }
        }
        healthStore.execute(statsQuery)
    }
    
    // MARK: - Active Energy
    private func startObservingActiveEnergy() {
        guard !isObservingActiveEnergy else { return }
        isObservingActiveEnergy = true
        
        guard let aeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let query = HKObserverQuery(sampleType: aeType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Active Energy Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchActiveEnergyBurned()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: aeType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (Active Energy) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for Active Energy: \(success)")
            }
        }
    }
    
    func fetchActiveEnergyBurned() {
        guard let aeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let now = Date()
        let cal = Calendar.current
        guard let startDay = cal.date(bySettingHour: 0, minute: 0, second: 0, of: now) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: now, options: .strictStartDate)
        let statsQuery = HKStatisticsQuery(quantityType: aeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, error in
            if let error = error {
                print("Fetch Active Energy error: \(error.localizedDescription)")
                return
            }
            guard let stats = stats, let sumQ = stats.sumQuantity() else {
                print("No active energy data found.")
                return
            }
            let kcals = sumQ.doubleValue(for: .kilocalorie())
            DispatchQueue.main.async {
                self?.activeEnergy = kcals
                print("fetchActiveEnergyBurned() - Active Energy: \(kcals) kcal")
            }
        }
        healthStore.execute(statsQuery)
    }
    
    // MARK: - Exercise Time
    private func startObservingExerciseTime() {
        guard !isObservingExerciseTime else { return }
        isObservingExerciseTime = true
        
        guard let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        let query = HKObserverQuery(sampleType: exerciseTimeType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Exercise Time Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchExerciseTime()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: exerciseTimeType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (Exercise Time) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for Exercise Time: \(success)")
            }
        }
    }
    
    func fetchExerciseTime() {
        guard let exerciseTimeType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        
        // Check authorization status for exercise time before executing the query.
        let status = healthStore.authorizationStatus(for: exerciseTimeType)
        if status != .sharingAuthorized {
            print("Fetch Exercise Time error: Authorization not determined")
            return
        }
        
        let now = Date()
        let cal = Calendar.current
        guard let startDay = cal.date(bySettingHour: 0, minute: 0, second: 0, of: now) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: now, options: .strictStartDate)
        let statsQuery = HKStatisticsQuery(quantityType: exerciseTimeType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, error in
            if let error = error {
                print("Fetch Exercise Time error: \(error.localizedDescription)")
                return
            }
            guard let stats = stats, let sumQ = stats.sumQuantity() else {
                print("No exercise time data found.")
                return
            }
            let minutes = sumQ.doubleValue(for: HKUnit.minute())
            DispatchQueue.main.async {
                self?.exerciseTime = minutes
                print("fetchExerciseTime() - Exercise Time: \(minutes) min")
            }
        }
        healthStore.execute(statsQuery)
    }
    
    // MARK: - Distance
    private func startObservingDistance() {
        guard !isObservingDistance else { return }
        isObservingDistance = true
        
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        let query = HKObserverQuery(sampleType: distanceType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Distance Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchDailyDistance()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: distanceType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (Distance) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for Distance: \(success)")
            }
        }
    }
    
    func fetchDailyDistance() {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        // Check authorization status for distance before executing the query.
        let status = healthStore.authorizationStatus(for: distanceType)
        if status != .sharingAuthorized {
            print("Fetch Distance error: Authorization not determined")
            return
        }
        
        let now = Date()
        let cal = Calendar.current
        guard let startDay = cal.date(bySettingHour: 0, minute: 0, second: 0, of: now) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: startDay, end: now, options: .strictStartDate)
        let statsQuery = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, error in
            if let error = error {
                print("Fetch Distance error: \(error.localizedDescription)")
                return
            }
            guard let stats = stats, let sumQ = stats.sumQuantity() else {
                print("No distance data found.")
                return
            }
            let meters = sumQ.doubleValue(for: HKUnit.meter())
            DispatchQueue.main.async {
                self?.distance = meters
                print("fetchDailyDistance() - Distance: \(meters) m")
            }
        }
        healthStore.execute(statsQuery)
    }
    
    // MARK: - Body Temperature (New)
    func fetchLatestBodyTemperature() {
        guard let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        // Check authorization status for body temperature before querying.
        let status = healthStore.authorizationStatus(for: temperatureType)
        if status != .sharingAuthorized {
            print("Fetch Body Temperature error: Authorization not determined")
            return
        }
        
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: temperatureType, predicate: nil, limit: 1, sortDescriptors: [sortDesc]) { [weak self] _, samples, error in
            if let error = error {
                print("Fetch Body Temperature error: \(error.localizedDescription)")
                return
            }
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No body temperature samples found.")
                return
            }
            // Assume temperature is recorded in Celsius.
            let celsiusValue = sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
            DispatchQueue.main.async {
                self?.bodyTemperature = celsiusValue
                print("fetchLatestBodyTemperature() - New Body Temp: \(celsiusValue)°C")
            }
        }
        healthStore.execute(query)
    }
    
    private func startObservingBodyTemperature() {
        guard !isObservingBodyTemperature else { return }
        isObservingBodyTemperature = true
        
        guard let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else { return }
        let query = HKObserverQuery(sampleType: temperatureType, predicate: nil) { [weak self] _, completion, error in
            if let error = error {
                print("Body Temperature Observer error: \(error.localizedDescription)")
            } else {
                self?.fetchLatestBodyTemperature()
            }
            completion()
        }
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: temperatureType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery (Body Temperature) error: \(error.localizedDescription)")
            } else {
                print("Background Delivery for Body Temperature: \(success)")
            }
        }
    }
}
