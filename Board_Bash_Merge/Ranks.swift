import SwiftUI
struct Ranks: View{
    var body: some View{
        ZStack{
            Color.black
                .ignoresSafeArea(edges: .all)
            Image("RanksView")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.4)
            Text("Coming Soon!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
                .frame(width: 300, height: 100)
                .background(Color.brown)
        }
    }
}

#Preview {
    Ranks()
}
