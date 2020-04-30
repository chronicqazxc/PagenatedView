//
//  ContentView.swift
//  PagenatedView
//
//  Created by Hsiao, Wayne on 2020/4/16.
//  Copyright © 2020 Hsiao, Wayne. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {

    var body: some View {
        
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    self.makeViewFromGeometry(geometry, demoItems: DemoWrapper1.shared.demoItems)
                        .background(Color.red)
                    self.makeViewFromGeometry(geometry, demoItems: DemoWrapper2.shared.demoItems)
                        .background(Color.green)
                }
            }
        }
    }
    
    init() {
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
    }
    
    func makeViewFromGeometry(_ geometry: GeometryProxy, demoItems: [DemoItem]) -> some View {
        
        return
            List {
                ForEach(demoItems, id: \.self) { item in
                    Button(action: item.action) {
                        Text(item.display)
                            .foregroundColor(.white)
                            .frame(width: geometry.size.width - 40,
                                   alignment: .center)
                    }
                }
            }
            .frame(width: geometry.size.width - 20, height: geometry.size.height, alignment: .center)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
