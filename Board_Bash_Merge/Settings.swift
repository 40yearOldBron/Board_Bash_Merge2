import SwiftUI
struct Settings: View{
    var body: some View{
        ZStack{
            Color.black
                .ignoresSafeArea(edges: .all)
            Image("SettingsView")
                .resizable()
                .ignoresSafeArea()
                .opacity(0.4)
            Text("Coming Soon!")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(.white)
                .frame(width: 300, height: 100)
                .background(Color.gray)
        }
    }
}

#Preview {
    Settings()
}

