//
//  DemoWrapper2.swift
//  PagenatedView
//
//  Created by YuHan Hsiao on 2020/4/20.
//  Copyright © 2020 Hsiao, Wayne. All rights reserved.
//

import Foundation
import Combine

struct User {
   let name: CurrentValueSubject<String, Never>
}

class UserHelper {
    let request: CurrentValueSubject<String, Never>
    var response = PassthroughSubject<String, Never>()
    var disposables = Set<AnyCancellable>()
    
    init(request: CurrentValueSubject<String, Never>) {
        self.request = request
        self.setup()
    }
    
    func setup() {
        request
            .sink { value in
                self.response.send(value)
        }
        .store(in: &disposables)
    }
}

final class DemoWrapper2 {

    static let shared = DemoWrapper2()
    var disposables = Set<AnyCancellable>()
    
    lazy var demoItems: [DemoItem] = [
        DemoItem(display: "Map", {
            let userSubject = PassthroughSubject<User, Never>()
            userSubject
               .map { $0.name }
               .sink { print($0) }
                .store(in: &self.disposables)
            let user = User(name: .init("User 1"))
            userSubject.send(user)
        }),
        
        DemoItem(display: "FlatMap", {
            let userSubject = PassthroughSubject<User, Never>()
            userSubject
                .flatMap { $0.name }
                .sink { print($0) }
                .store(in: &self.disposables)
            let user = User(name: .init("User 1"))
            userSubject.send(user)
        }),
        
        DemoItem(display: "MaximumFlatMap", {
            let userSubject = PassthroughSubject<User, Never>()
            let user = User(name: .init("Wayne"))
            let anotherUser = User(name: .init("Allen"))
            
            userSubject
                .flatMap(maxPublishers: .max(1), { $0.name })
                .sink { print($0) }
                .store(in: &self.disposables)
            
            userSubject.send(user)
            userSubject.send(anotherUser)
            user.name.send("Wayne H")
            anotherUser.name.send("Allen W")
        }),
        
        DemoItem(display: "SwitchToLatest", {
            let publisherContainer = PassthroughSubject<UserHelper, Never>()
            let user1 = UserHelper(request: .init("Wayne H"))
            let user2 = UserHelper(request: .init("David C"))
            
            publisherContainer
                .map { $0.response }
                .switchToLatest()
                .sink { print($0) }
                .store(in: &self.disposables)
            
            publisherContainer.send(user1)
            publisherContainer.send(user2)
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                user1.request.send("Wayne H")
            }
            user2.request.send("David C")
        }),
        
        DemoItem(display: "PassthroughSuject", {
            let publisher = PassthroughSubject<String, Error>()

            publisher.send("0")
            
            publisher
                .removeDuplicates()
                .sink(receiveCompletion: {
                    switch $0 {
                    case .finished:
                        print("Finished")
                    case .failure(let error):
                        print(error)
                    }
                }) {
                    print($0)
            }
            .store(in: &self.disposables)
            
            publisher.send("1")
            publisher.send("1")
            publisher.send("2")
            publisher.send(completion: Subscribers.Completion.finished)
        }),
        
        DemoItem(display: "CurrentValueSubject", {
            let publisher = CurrentValueSubject<String, Never>("1")
            publisher.send("2")
            publisher.send("3")
            publisher
                .sink(receiveCompletion: {
                    switch $0 {
                    case .finished:
                        print("Finished")
                    case .failure(let error):
                        print(error)
                    }
                }) {
                    print($0)
            }
            .store(in: &self.disposables)
            publisher.send("4")
            publisher.send("5")
        }),
        
        // Custom subscriber (Subclass of AnySubscriber)
        DemoItem(display: "CustomSubscriber #1", {
            let publisher = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            publisher.subscribe(MySubscriber())
        }),
        
        // Custom subscriber (Created from AnySubscriber)
        DemoItem(display: "CustomSubscriber #2", {
            let publisher = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            
            let subscriber = AnySubscriber<Date, Never>(receiveSubscription: { (subscription: Subscription) in
                print("published                             received")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    subscription.request(.max(3))
                }
            }, receiveValue: {
                print("\($0)             \(Date())")
                return Subscribers.Demand.none
            }, receiveCompletion: { _ in
                print("---done---")
            })
            
            publisher.subscribe(subscriber)
        }),
        
        DemoItem(display: "Subscribe(on:), Receive(on:) #1", {
            URLSession.shared.dataTaskPublisher(for: URL(string: "https://www.vadimbulavin.com")!)
                .subscribe(on: DispatchQueue.global()) // Subscribe on the main thread
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in
                    print(Thread.isMainThread)
                },
                      receiveValue: { _ in
                        print(Thread.isMainThread) // Are we on the main thread?
                })
                .store(in: &self.disposables)
        }),
        
        DemoItem(display: "Subscribe(on:), Receive(on:) #2", {
            let deferredPublisher = Deferred { () -> Just<Int> in
                DispatchQueue.main.async {
                    NSLog("Publisher1: \(Thread.isMainThread)")
                }
                NSLog("Publisher2: \(Thread.isMainThread)")
                return Just(1)
            }
            
            deferredPublisher
                .map { return $0 }
                .receive(on: DispatchQueue.global())
                .map { return $0 }
                .subscribe(on: DispatchQueue.global())
                .sink { (int) in
                    NSLog("Subscriber: \(Thread.isMainThread)")
                    print(int)
            }
            .store(in: &self.disposables)
        }),
        
        DemoItem(display: "Throttle(latest: false)", {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSXXXXX"
            
            let now = DispatchTime.now()
            let delay1 = now + 0.2
            let delay2 = now + 0.3
            let delay3 = now + 0.7
            let delay4 = now + 0.8
            let delay5 = now + 1.2
            let delay6 = now + 1.3
            let timeNow = Date()
            let start = now.uptimeNanoseconds
            
            let passthroough = PassthroughSubject<String, Never>()
            passthroough
                .throttle(for: 0.5, scheduler: DispatchQueue.global(), latest: false)
                .sink { value in
                    let end = DispatchTime.now()
                    let nanoTime = end.uptimeNanoseconds - start
                    let timeInterval = Double(nanoTime) / 1_000_000_000
                    print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): receive \(value) ")
            }
            .store(in: &self.disposables)
            
            DispatchQueue.global().asyncAfter(deadline: delay1) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 1 ")
                
                passthroough.send("1")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay2) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 2 ")
                
                passthroough.send("2")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay3) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 3 ")
                
                passthroough.send("3")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay4) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 4 ")
                
                passthroough.send("4")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay5) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 5 ")
                
                passthroough.send("5")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay6) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 6 ")
                
                passthroough.send("6")
            }
        }),
        
        DemoItem(display: "Throttle(latest: true)", {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSXXXXX"
            
            let now = DispatchTime.now()
            let delay1 = now + 0.2
            let delay2 = now + 0.3
            let delay3 = now + 0.7
            let delay4 = now + 0.8
            let delay5 = now + 1.2
            let delay6 = now + 1.3
            let timeNow = Date()
            let start = now.uptimeNanoseconds
            
            let passthroough = PassthroughSubject<String, Never>()
            passthroough
                .throttle(for: 0.5, scheduler: DispatchQueue.global(), latest: true)
                .sink { value in
                    let end = DispatchTime.now()
                    let nanoTime = end.uptimeNanoseconds - start
                    let timeInterval = Double(nanoTime) / 1_000_000_000
                    print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): receive \(value) ")
            }
            .store(in: &self.disposables)
            
            DispatchQueue.global().asyncAfter(deadline: delay1) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 1 ")
                
                passthroough.send("1")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay2) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 2 ")
                
                passthroough.send("2")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay3) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 3 ")
                
                passthroough.send("3")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay4) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 4 ")
                
                passthroough.send("4")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay5) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 5 ")
                
                passthroough.send("5")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay6) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))): send 6 ")
                
                passthroough.send("6")
            }
        }),
        
        DemoItem(display: "Debounce", {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSXXXXX"
            let now = DispatchTime.now()
            let delay1 = now + 0.2
            let delay2 = now + 0.7
            let delay3 = now + 0.8
            let delay4 = now + 1.7
            let delay5 = now + 2.2
            let delay6 = now + 2.3
            let timeNow = Date()
            let start = now.uptimeNanoseconds
            
            let passthrough = PassthroughSubject<String, Never>()
            passthrough
                .debounce(for: 0.5, scheduler: DispatchQueue.global())
                .sink { string in
                    if string == "3" || string == "6" {
                        let end = DispatchTime.now()
                        let nanoTime = end.uptimeNanoseconds - start
                        let timeInterval = Double(nanoTime) / 1_000_000_000
                        print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))) : receive \(string)")
                    } else {
                        print(string)
                    }
            }
            .store(in: &self.disposables)
            
            DispatchQueue.global().asyncAfter(deadline: delay1) {
                passthrough.send("1")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay2) {
                passthrough.send("2")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay3) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))) : send 3")
                passthrough.send("3")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay4) {
                passthrough.send("4")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay5) {
                passthrough.send("5")
            }
            
            DispatchQueue.global().asyncAfter(deadline: delay6) {
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start
                let timeInterval = Double(nanoTime) / 1_000_000_000
                print("\(dateFormatter.string(from: timeNow.addingTimeInterval(timeInterval))) : send 6")
                passthrough.send("6")
            }
        }),
    ]
    
    private init() {
        
    }
}
