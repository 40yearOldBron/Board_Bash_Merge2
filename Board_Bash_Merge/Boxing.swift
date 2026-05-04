import SwiftUI
import AVFoundation

struct Boxing: View {
    let X = "Fighting x 12"
    let Y = "PounchFixed"
    let Z = "KickFixed"
    let A = "Block"

    @State var win = false
    @State var rand: Int
    @State var change = "Fighting x 12"
    @State var badChange = "badStance"
    @State var badDam = 100
    @State var goDam = 100
    @Binding var xP: Double

    @State var timerFinished = false
    @State var timeRemaining = 30.0

    @State var characterX: CGFloat = 0.0
    @State var characterY: CGFloat = -75
    @State var BcharacterX: CGFloat = 0.0
    @State var BcharacterY: CGFloat = -75

    @State var isAnimating = false
    @State var isJumping = false

    @State private var isBlocking = false
    @State private var canBlock = true
    @State private var pressStartTime: Date? = nil

    @State var moveTimer: Timer? = nil
    @State var walkTimer: Timer? = nil
    @State var isWalking = false

    @State private var canPunch = true
    @State private var canKick = true
    @State private var audioPlayer: AVAudioPlayer?
    
    let minX: CGFloat = -150
    let maxX: CGFloat = 150
    let moveStep: CGFloat = 6

    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    // sounds
    func playSound(_ name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
    
    // MARK: - Animation
    func playAnimation(_ imageName: String) {
        if isBlocking { return }

        change = imageName
        isAnimating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isBlocking {
                change = X
            }
            isAnimating = false
        }
    }

    // MARK: - Jump
    func jump() {
        guard !isJumping && !isBlocking else { return }

        isJumping = true
        withAnimation(.easeOut(duration: 0.2)) {
            characterY -= 100
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.2)) {
                characterY += 100
            }
            isJumping = false
        }
    }

    // MARK: - Movement
    func startMoving(direction: CGFloat) {
        stopMoving()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            characterX = min(max(characterX + direction * moveStep, minX), maxX)
        }
    }

    func stopMoving() {
        moveTimer?.invalidate()
        moveTimer = nil
    }

    // MARK: - Punch
    func doPunch() {
        guard canPunch else { return }
        canPunch = false
        playAnimation(Y)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            canPunch = true
        }
    }

    // MARK: - Kick
    func doKick() {
        guard canKick else { return }
        canKick = false
        playAnimation(Z)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canKick = true
        }
    }

    var body: some View {
        ZStack {
            Image("BoxingBG")
                .resizable()
                .ignoresSafeArea()

            // TIMER
            Text(timeString)
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(timeRemaining <= 5 ? .red : .white)
                .offset(x: 0, y: -335)
                .onReceive(countdownTimer) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timerFinished = true
                    }
                }

            // HEALTH
            Text("\(badDam)")
                .background(Color.white)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .offset(x: 155, y: -335)

            Text("\(goDam)")
                .background(Color.white)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .offset(x: -155, y: -335)

            // ENEMY
            Image(badChange)
                .frame(width: 100, height: 200)
                .scaleEffect(0.75)
                .offset(x: BcharacterX, y: BcharacterY)

            // PLAYER
            Image(change)
                .frame(width: 100, height: 200)
                .scaleEffect(0.75)
                .offset(x: characterX, y: characterY)

            // TOP BUTTONS
            VStack {
                HStack {
                    Button("SP1") {}
                        .frame(width: 60, height: 40)
                        .background(Color.gray)
                        .offset(x: -95, y: 225)
                        .opacity(0.08)

                    Button("SP2") {}
                        .frame(width: 60, height: 40)
                        .background(Color.gray)
                        .offset(x: -65, y: 225)
                        .opacity(0.08)

                    // MARK: - JUMP / BLOCK BUTTON
                    Text("Jump")
                        .frame(width: 60, height: 90)
                        .background(Color.gray)
                        .offset(x: 100, y: 210)
                        .opacity(0.08)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if pressStartTime == nil {
                                        pressStartTime = Date()
                                    }

                                    if let start = pressStartTime,
                                       Date().timeIntervalSince(start) > 0.25,
                                       !isBlocking,
                                       canBlock {

                                        isBlocking = true
                                        change = A
                                    }
                                }
                                .onEnded { _ in
                                    let duration = Date().timeIntervalSince(pressStartTime ?? Date())
                                    pressStartTime = nil

                                    if isBlocking {
                                        isBlocking = false
                                        change = X

                                        canBlock = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            canBlock = true
                                        }

                                    } else if duration < 0.1 {
                                        jump()
                                        playAnimation(X)
                                    }
                                }
                        )
                }
            }

            // MOVEMENT
            HStack {
                Button("Left") {}
                    .frame(width: 75, height: 75)
                    .background(Color.gray)
                    .offset(x: 10, y: 300)
                    .opacity(0.08)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in startMoving(direction: -1.5) }
                            .onEnded { _ in stopMoving() }
                    )

                Spacer()

                Button("Right") {}
                    .frame(width: 75, height: 75)
                    .background(Color.gray)
                    .offset(x: -110, y: 300)
                    .opacity(0.08)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in startMoving(direction: 1.5) }
                            .onEnded { _ in stopMoving() }
                    )

                Spacer()
            }

            // ATTACKS
            Button("Kick") {
                doKick()
            }
            .frame(width: 55, height: 100)
            .background(canKick ? Color.gray : Color.red)
            .offset(x: 120, y: 300)
            .opacity(0.08)

            Button("Punch") {
                doPunch()
            }
            .frame(width: 55, height: 100)
            .background(canPunch ? Color.gray : Color.red)
            .offset(x: 177, y: 300)
            .opacity(0.08)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                if !isAnimating && !isBlocking {
                    change = (change == X) ? "Walk" : X
                }
            }
        }
    }
}

#Preview {
    Boxing(rand: 0, xP: .constant(0))
}
