//
//  ContentView.swift
//  CborCoseExample
//
//  Created by Antonio on 02/12/24.
//

import SwiftUI

struct ContentView: View {
    
    @State var cose1SignView: Bool = false
    @State var cborDecodeView: Bool = false
    
    var body: some View {
        NavigationStack(root: {
            VStack {
                CustomButton(title: "Cose1SignView", action: {
                    cose1SignView = true
                })
                CustomButton(title: "CborDecodeView", action: {
                    cborDecodeView = true
                })
            }
            .padding()
            .navigationDestination(isPresented: $cose1SignView, destination: {
                Cose1SignView()
            })
            .navigationDestination(isPresented: $cborDecodeView, destination: {
                CborDecodeView()
            })
        })
        
        
       
    }
}

#Preview {
    ContentView()
}
