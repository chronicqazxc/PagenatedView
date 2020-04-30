//
//  MySubscriber.swift
//  PagenatedView
//
//  Created by YuHan Hsiao on 2020/4/21.
//  Copyright © 2020 Hsiao, Wayne. All rights reserved.
//

import Foundation
import Combine

class MySubscriber: Subscriber {
    typealias Input = Date
    typealias Failure = Never
    var subscription: Subscription?
    
    func receive(subscription: Subscription) {
        self.subscription = subscription
        print("published                             received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            subscription.request(.max(3))
        }
    }
    
    func receive(_ input: Date) -> Subscribers.Demand {
        print("\(input)             \(Date())")
        return Subscribers.Demand.none
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("\(Thread.isMainThread)")
        print("---done---")
    }
}
