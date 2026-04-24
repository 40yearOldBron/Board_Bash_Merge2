//
//  ContentView.swift
//  Board_Bash_Merge
//
//  Created by 64011955 on 4/22/26.
//
import SwiftUI
struct ContentView: View {
    @State private var xP = 0.0
    @State private var level = 0
    var body: some View {
        NavigationStack {
            ZStack{
                Image("HomeScreenBG")
                    .ignoresSafeArea()
                
                ProgressView(value: xP)
                                   .padding(.bottom, 225.0)
                                   .frame(width: 350.0)

                Text("Level \(level)")
                    .font(.body)
                    .fontWeight(.black)
                    .foregroundColor(Color.white)
                    .padding(.bottom,194.0)
                    
                VStack{
                    HStack{
                        Button("Settings") {
                        }
                        .frame(width: 180, height:100)
                        .background(Color.yellow)
                        .padding(.trailing)
                        .padding(.bottom,800.0)
                        .font(.largeTitle)
                        .opacity(0.0)
                        Spacer()
                    }
                }
                
                VStack{
                    HStack{
                        Button("Ranks") {
                        }
                        .frame(width: 190, height:70)
                        .background(Color.yellow)
                        .padding(.leading, 75.0)
                        .padding(.trailing, 25.0)
                        .font(.largeTitle)
                        .opacity(0.0)
          
                        Button("Friends") {
                        }
                        .frame(width: 190, height:70)
                        .background(Color.yellow)
                        .padding(.trailing, 75.0)
                        .font(.largeTitle)
                        .opacity(0.0)
                    }
                    .offset(x:0, y:-205.0)
                }
                .padding(2.0)
                
                VStack{
                    Button("Shop") {
                    }
                    .frame(width: 300, height: 100)
                    .background(Color.yellow)
                    .offset(x:5.0, y:67.0)
                    .font(.largeTitle)
                    .opacity(0.0)
                    
                    NavigationLink(destination: CheckersView()) {
                        Text("Play")
                            .frame(width: 300, height: 130)
                            .background(Color.yellow)
                            .font(.largeTitle)
                            .opacity(0.0)
                    }
                    .offset(x:0.0 ,y:250.0)
                }
            }
        }
        .onChange(of: xP) { oldValue, newValue in
            if newValue >= 100 {
                level += 1
                xP = 0
            }
        }
    }
}
#Preview {
    ContentView()
}
