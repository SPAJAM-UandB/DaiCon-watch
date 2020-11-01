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
            Section(header: Text("List")) {
                ForEach(deepViewModel.sound_lists) { sound in
                    if sound.name != "" {
                        HStack {
                            Image(deepViewModel.get_icon(filename:sound.name))
                                .resizable()
                                .frame(width: 35.0, height: 35.0, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(20)
                                .padding()
                            Button(sound.name.split(separator: "_").joined(separator: " ")){
                                deepViewModel.select_state.toggle()
                                deepViewModel.select_filename = sound.name
                                deepViewModel.set_select_location()
                                deepViewModel.select_label = deepViewModel.get_icon(filename:sound.name)
                                deepViewModel.region = MKCoordinateRegion(center: .init(latitude: deepViewModel.select_latitude, longitude: deepViewModel.select_longitude), latitudinalMeters: 200, longitudinalMeters: 200)
                            }
                            .font(.system(size: 16))
                            .fullScreenCover(isPresented: $deepViewModel.select_state, content: DetailView.init)
                        }
                    }
                }.onDelete(perform: delete)
            }
        }.navigationBarTitle("Glab Sound")
    }
    func delete(at offsets: IndexSet) {
        deepViewModel.delete_file(filename: deepViewModel.sound_lists[offsets.first!].name)
       if let first = offsets.first {
        deepViewModel.sound_lists.remove(at: first)
       }
    }
}

 
struct SecondView: View {
    @EnvironmentObject var deepViewModel: DeepViewModel
    @Binding var secondScreenShown:Bool

    var body: some View {
        VStack{
            Text("\(deepViewModel.label)")
            Text("\(deepViewModel.activity_name[deepViewModel.label] ?? 0.0)")
//            Text("\(deepViewModel.latitude)")
//            Text("\(deepViewModel.longitude)")
            Button("End"){
                self.secondScreenShown = false
            }
        }
    }
}

struct DetailView: View {
    @EnvironmentObject var deepViewModel: DeepViewModel
    @State var placeScreenShown:Bool = false
    
    var body: some View {
        VStack{
            HStack{
                Image(deepViewModel.select_label)
                    .resizable()
                    .frame(width: 25.0, height: 25.0, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding()
                Text("\(deepViewModel.select_filename.split(separator: "_").joined(separator: " "))")
                    .font(.system(size: 10))
            }
            Image("play_icon")
                .resizable()
                .frame(width: 70.0, height: 70.0, alignment: .leading)
                .onTapGesture {
                    deepViewModel.play(file_name: deepViewModel.select_filename)
                }
            HStack{
                Button("Place"){
                    self.placeScreenShown.toggle()
                }.fullScreenCover(isPresented: self.$placeScreenShown, content: MapView.init)
                
                Button("Back"){
                    deepViewModel.select_state = false
                }
                .foregroundColor(Color.white)
                .background(Color.red)
                .cornerRadius(5)
            }
        }
    }
}


struct MapView: View {
    
    @EnvironmentObject var deepViewModel: DeepViewModel
    
    var body: some View {
        Map(coordinateRegion: $deepViewModel.region)
            .edgesIgnoringSafeArea(.all)
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
