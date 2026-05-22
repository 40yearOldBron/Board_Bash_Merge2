import SwiftUI

struct End: View {

    @State var rand: Int
    @Binding var xP: Double

    var body: some View {

        NavigationStack {

            ZStack {

                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 40) {

                    Image(rand == 1 ? "BlueKing" : "RedSmirking")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)

                    Text(rand == 1 ? "YOU WIN" : "YOU LOSE")
                        .font(.system(size: 50))
                        .fontWeight(.black)
                        .foregroundColor(.white)

                    NavigationLink(destination: ContentView()) {

                        Text("Home")
                            .frame(width: 220, height: 70)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .font(.title)
                            .fontWeight(.bold)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}

#Preview {

    End(
        rand: 0,
        xP: .constant(0)
    )
}
