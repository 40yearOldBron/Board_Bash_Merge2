import SwiftUI
import AVFoundation

// MARK: - ContentView

struct ContentView: View {
    
    @State private var xP = 0.0
    @State private var level = 0
    @State private var gameID = UUID()  // 🔄 forces fresh CheckersView on each Play tap

    // 🎵 MUSIC
    @State private var player: AVAudioPlayer?

    var body: some View {
        NavigationStack {
            ZStack {
                Image("HomeScreenBG")
                    .ignoresSafeArea()
                
                ProgressView(value: xP)
                    .padding(.bottom, 225.0)
                    .frame(width: 350.0)

                Text("Level \(level)")
                    .font(.body)
                    .fontWeight(.black)
                    .foregroundColor(Color.white)
                    .padding(.bottom, 194.0)
                    
                VStack {
                    HStack {
                        NavigationLink(destination: Settings()) {
                            Text("Settings")
                                .frame(width: 180, height: 100)
                                .background(Color.yellow)
                                .padding(.trailing)
                                .padding(.bottom, 800.0)
                                .font(.largeTitle)
                                .opacity(0.0)
                        }
                        Spacer()
                    }
                }
                
                VStack {
                    HStack {
                        NavigationLink(destination: Ranks()) {
                            Text("Ranks")
                                .frame(width: 190, height: 70)
                                .background(Color.yellow)
                                .padding(.leading, 75.0)
                                .padding(.trailing, 25.0)
                                .font(.largeTitle)
                                .opacity(0.0)
                        }
          
                        NavigationLink(destination: Friends()) {
                            Text("Friends")
                                .frame(width: 190, height: 70)
                                .background(Color.yellow)
                                .padding(.trailing, 75.0)
                                .font(.largeTitle)
                                .opacity(0.0)
                        }
                    }
                    .offset(x: 0, y: -205.0)
                }
                .padding(2.0)
                
                VStack {
                    NavigationLink(destination: Shop()) {
                        Text("Shop")
                            .frame(width: 300, height: 100)
                            .background(Color.yellow)
                            .font(.largeTitle)
                            .opacity(0.0)
                    }
                    .offset(x: 5.0, y: 67.0)
                    
                    NavigationLink(destination:
                        CheckersView()
                            .id(gameID)  // 🆔 new UUID = SwiftUI rebuilds the view from scratch
                            .onAppear {
                                stopMusic()  // ⛔ stop menu music when entering game
                            }
                    ) {
                        
                        Text("Play")
                            .frame(width: 300, height: 130)
                            .background(Color.yellow)
                            .font(.largeTitle)
                            .opacity(0.0)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        gameID = UUID()  // 🔄 rotate ID so next tap also gets a fresh board
                        UserDefaults.standard.set(false, forKey: "gameInProgress")  // 🗑️ wipe saved game
                        UserDefaults.standard.removeObject(forKey: "savedPieces")
                        UserDefaults.standard.removeObject(forKey: "savedTurn")
                    })
                    .offset(x: 0.0, y: 250.0)
                }
            }
        }
        .onAppear {
            playMusic()  // ▶️ start menu music
        }
        .onDisappear {
            stopMusic()  // ⛔ extra safety
        }
        .onChange(of: xP) { oldValue, newValue in
            if newValue >= 100 {
                level += 1
                xP = 0
            }
        }
    }
    
    // 🎵 PLAY
    func playMusic() {
        guard let url = Bundle.main.url(forResource: "03 Cotton Candy Up In Here", withExtension: "mp3") else {
            print("music file not found")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1  // 🔁 loop forever
            player?.volume = 0.5
            player?.play()
        } catch {
            print("error playing music")
        }
    }
    
    func stopMusic() {
        player?.stop()
    }
}

#Preview {
    ContentView()
}
