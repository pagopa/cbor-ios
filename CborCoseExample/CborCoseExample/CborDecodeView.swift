//
//  CborDecodeView.swift
//  CborCoseExample
//
//  Created by Antonio on 02/12/24.
//


import SwiftUI
import IOWalletCBOR

struct CborDecodeView : View {
    @State var data: String = ""
    @State var json: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    GroupBox(content: {
                        CustomTextField(placeholder: "Data", text: $data)
                    }, label: {
                        Text("Data")
                    })
                    
                    CustomButton(title: "Decode", action: {
                        guard let bytes = Data(base64Encoded: data) else {
                            json = ""
                            return
                        }
                        json = CborCose.decodeCBOR(data: bytes) ?? ""
                    })
                    
                    GroupBox(content: {
                        CustomTextField(placeholder: "JSON", text: $json)
                    }, label: {
                        Text("JSON")
                    })
                }
            }
        }
    }
}


#Preview {
    CborDecodeView()
}
