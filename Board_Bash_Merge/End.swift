//
//  End.swift
//  Board_Bash_Merge
//
//  Created by 64011955 on 5/15/26.
//
import SwiftUI
import AVFoundation

struct End: View {
    
    var rand: Int
    @Binding var xP: Double
    
    var body: some View {
        ZStack {
            Button("Restart") {}
                .frame(width: 300, height: 100)
                .background(Color.yellow)
                
                .font(.largeTitle)
                .opacity(1.0)
            
        }
    }
}

#Preview {
    End(rand: 0, xP: .constant(0))
}
