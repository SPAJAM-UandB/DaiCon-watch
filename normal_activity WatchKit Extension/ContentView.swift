//
//  ContentView.swift
//  normal_activity WatchKit Extension
//
//  Created by koki-ta on 2020/09/27.
//

import SwiftUI
import MapKit


struct ContentView: View {
    @EnvironmentObject var deepViewModel: DeepViewModel
    @State var secondScreenShown = false
    
    var body: some View {
        Form {
            Section(header: Text("Get sound")) {
                NavigationLink(destination: SecondView(secondScreenShown: $secondScreenShown)
                                .onAppear(){
                                    deepViewModel.record_start()
                                }.onDisappear(){
                                    deepViewModel.record_end()
                                }
                               , isActive: $secondScreenShown, label: {Text("Start")})
            }
        }.navigationBarTitle("Glab Sound")
    }
}

 
struct SecondView: View {
    @EnvironmentObject var deepViewModel: DeepViewModel
    @Binding var secondScreenShown:Bool

    var body: some View {
        VStack{
            Text("\(deepViewModel.label)")
            Text("\(deepViewModel.activity_name[deepViewModel.label] ?? 0.0)")
            Button("End"){
                self.secondScreenShown = false
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
