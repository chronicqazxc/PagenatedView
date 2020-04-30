//
//  DemoWrapper1.swift
//  PagenatedView
//
//  Created by YuHan Hsiao on 2020/4/19.
//  Copyright © 2020 Hsiao, Wayne. All rights reserved.
//

import Foundation
import Combine

extension Notification.Name {
    static let CustomNotification = Notification.Name("CustomNotification")
}

enum DemoError: Error {
    case errorTest
}

final class DemoWrapper1 {
    var disposables: Set<AnyCancellable> = Set<AnyCancellable>()
    var userPreference = UserPreference()
    var timerCancellable: AnyCancellable!
    var deferredIntsPublisher: AnyPublisher<Int, Never>!
    static let shared = DemoWrapper1()
    
    private init() {
        setupKVOObserving()
        setupDeferred()
    }
    
    lazy var demoItems: [DemoItem] = [
        DemoItem(display: "Timer", {
            self.timerCancellable = Timer.publish(every: 1.0, on: .main, in: .default)
                .autoconnect()
                .map { (date: Date) -> String in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
                    return formatter.string(from: date)
            }
            .sink { (time) in
                print(time)
            }
        }),
        
        DemoItem(display: "Stop timer", {
            self.timerCancellable?.cancel()
        }),
        
        DemoItem(display: "URLSession", {
            let url = URL(string: "https://www.google.com")!
            let connectable = URLSession.shared.dataTaskPublisher(for: url)
                .map { $0.data }
                .catch() { _ in Just(Data()) }
                .share()
                .makeConnectable()
            
            connectable.sink(receiveCompletion: { print("Received completion 1: \($0).") },
                                                 receiveValue: { print("Received data 1: \($0.count) bytes.") })
                .store(in: &self.disposables)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                connectable.sink(receiveCompletion: { print("Received completion 2: \($0).") },
                                                     receiveValue: { print("Received data 2: \($0.count) bytes.") })
                    .store(in: &self.disposables)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                connectable.connect()
                    .store(in: &self.disposables)
            }
        }),
        
        DemoItem(display: "KVO observing", {
            self.userPreference.age = 10
        }),
        
        DemoItem(display: "Deferred", {
            self.deferredIntsPublisher
                .sink(receiveCompletion: { _ in
                print("Complete.")
            }) {
                print($0)
            }
            .store(in: &self.disposables)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.deferredIntsPublisher.sink(receiveCompletion: { _ in
                    print("Complete.")
                }) {
                    print($0)
                }
                .store(in: &self.disposables)
            }
        }),
        
        DemoItem(display: "Empty", {
            Empty<Any, Never>(completeImmediately: true).sink(receiveCompletion: { _ in
                print("Empty complete")
            }, receiveValue: {
                print($0)
            })
                .store(in: &self.disposables)
        }),
        
        DemoItem(display: "Fail", {
            Fail<Any, DemoError>(error: DemoError.errorTest)
                .sink(receiveCompletion: {
                    print("Fail completed: \($0)")
                }, receiveValue: {
                    print($0)
                })
                .store(in: &self.disposables)
        }),
        
        DemoItem(display: "Record", {
            let record = Record<String, Never> { recording in
                recording.receive("one")
                recording.receive("two")
                recording.receive("three")
                recording.receive(completion: .finished)
            }
            
            record.sink(receiveCompletion: {
                print("Recrod: \($0)")
            }, receiveValue: {
                print($0)
            })
                .store(in: &self.disposables)
        }),
        
        DemoItem(display: "Just", {
            Just<String>("Just published")
                .sink(receiveCompletion: {
                print("Just completed: \($0)")
            }) {
                print("Just received: \($0)")
            }
            .store(in: &self.disposables)
        }),
        
        DemoItem(display: "Notification", {
            NotificationCenter.default.publisher(for: Notification.Name.CustomNotification)
                .sink { _ in
                    print("Notification received")
            }
            .store(in: &self.disposables)
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                NotificationCenter.default.post(name: Notification.Name.CustomNotification, object: nil)
            }
        })
    ]
    
    func setupKVOObserving() {
        self.userPreference
            .publisher(for: \.age)
            .dropFirst()
            .sink { age in print ("User age: \(age).") }
            .store(in: &disposables)
    }
    
    func setupDeferred() {
        deferredIntsPublisher = Deferred { () -> Publishers.Sequence<[Int], Never> in
            print("\(Date()) Deferred publisher generated.")
            return Publishers.Sequence<[Int], Never>(sequence: [1, 2, 3])
        }.eraseToAnyPublisher()
    }
}
