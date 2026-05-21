import SwiftUI
import AVFoundation

struct End: View {

    @Environment(\.dismiss) var dismiss

    var rand: Int
    @Binding var xP: Double
    var onGoHome: (() -> Void)? = nil

    var body: some View {
        ZStack {

            Color(.gray)
                .ignoresSafeArea()

            Image("BlueKing")
                .offset(x: 0.0, y: -220)
                .opacity(rand == 1 ? 1.0 : 0.2)

            Image("RedKing")
                .offset(x: 0.0, y: 230)
                .opacity(rand == 0 ? 1.0 : 0.2)

            Button("Home") {
                onGoHome?()
            }
            .frame(width: 300, height: 100)
            .background(Color.white)
            .foregroundColor(Color.blue)
            .cornerRadius(20.0)
            .font(.largeTitle)
            .fontWeight(.bold)
        }
    }
}

#Preview {
    End(rand: 0, xP: .constant(0))
}
