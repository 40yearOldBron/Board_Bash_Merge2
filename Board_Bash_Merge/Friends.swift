import SwiftUI
struct Friends: View{
    var body: some View{
        ZStack{
            Color.black
                .ignoresSafeArea(edges: .all)
            Image("FriendsView")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.4)
            Text("Coming Soon!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
                .frame(width: 300, height: 100)
                .background(Color.pink)
        }
    }
}

#Preview {
    Friends()
}

