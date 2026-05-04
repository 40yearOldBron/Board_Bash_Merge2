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

    // MARK: - AI State
    @State private var aiMoveTimer: Timer? = nil
    @State private var aiActionTimer: Timer? = nil
    @State private var aiIsAnimating = false
    @State private var aiIsBlocking = false
    @State private var aiMoveDirection: CGFloat = 0
    @State private var aiMoveTimer2: Timer? = nil  // smooth movement timer

    let minX: CGFloat = -150
    let maxX: CGFloat = 150
    let moveStep: CGFloat = 6
    let aiCloseRange: CGFloat = 120  // distance at which AI starts attacking

    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // Distance between player and AI opponent
    var distanceBetweenFighters: CGFloat {
        abs(characterX - BcharacterX)
    }

    // MARK: - Sound
    func playSound(_ name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }

    // MARK: - Player Animation
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

    // MARK: - AI Animation
    func playAIAnimation(_ imageName: String) {
        guard !aiIsAnimating else { return }
        aiIsAnimating = true
        badChange = imageName
        let duration: Double = imageName == "badKick" ? 0.8 : 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if !aiIsBlocking {
                badChange = "badStance"
            }
            aiIsAnimating = false
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

    // MARK: - Player Movement
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

    // MARK: - Player Attacks
    func doPunch() {
        guard canPunch else { return }
        canPunch = false
        playAnimation(Y)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            canPunch = true
        }
    }

    func doKick() {
        guard canKick else { return }
        canKick = false
        playAnimation(Z)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canKick = true
        }
    }

    // MARK: - AI Brain
    func startAI() {
        // Smooth movement loop (runs every 0.03s like the player)
        aiMoveTimer2 = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            guard aiMoveDirection != 0 else { return }
            BcharacterX = min(max(BcharacterX + aiMoveDirection * 4, minX), maxX)
        }

        // Decision loop — AI picks what to do every 0.4–0.9s
        scheduleNextAIDecision()
    }

    func scheduleNextAIDecision() {
        let delay = Double.random(in: 0.4...0.9)
        aiActionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            performAIDecision()
            scheduleNextAIDecision()
        }
    }

    func performAIDecision() {
        let isClose = distanceBetweenFighters < aiCloseRange

        if isClose {
            // When close: 40% attack, 25% block, 20% dodge back, 15% idle
            let roll = Int.random(in: 0...99)
            switch roll {
            case 0...39:
                aiDoAttack()
            case 40...64:
                aiDoBlock()
            case 65...84:
                // Dodge away from player
                let dodgeDir: CGFloat = BcharacterX > characterX ? 1 : -1
                aiMoveDirection = dodgeDir
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.5)) {
                    aiMoveDirection = 0
                }
            default:
                aiMoveDirection = 0
            }
        } else {
            // When far: 60% move toward player, 25% random drift, 15% idle
            let roll = Int.random(in: 0...99)
            switch roll {
            case 0...59:
                // Advance toward player
                aiMoveDirection = BcharacterX > characterX ? -1 : 1
                let moveDur = Double.random(in: 0.3...0.7)
                DispatchQueue.main.asyncAfter(deadline: .now() + moveDur) {
                    aiMoveDirection = 0
                }
            case 60...84:
                // Random lateral drift
                aiMoveDirection = Bool.random() ? 1 : -1
                let moveDur = Double.random(in: 0.2...0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + moveDur) {
                    aiMoveDirection = 0
                }
            default:
                aiMoveDirection = 0
            }
        }
    }

    func aiDoAttack() {
        guard !aiIsAnimating && !aiIsBlocking else { return }
        // 55% punch, 45% kick
        if Bool.random() {
            playAIAnimation("badPunch")   // use your actual bad-guy punch image name
        } else {
            playAIAnimation("badKick")    // use your actual bad-guy kick image name
        }
    }

    func aiDoBlock() {
        guard !aiIsAnimating else { return }
        aiIsBlocking = true
        badChange = "badBlock"            // use your actual bad-guy block image name
        let blockDur = Double.random(in: 0.4...1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + blockDur) {
            aiIsBlocking = false
            badChange = "badStance"
        }
    }

    func stopAI() {
        aiMoveTimer?.invalidate()
        aiMoveTimer = nil
        aiMoveTimer2?.invalidate()
        aiMoveTimer2 = nil
        aiActionTimer?.invalidate()
        aiActionTimer = nil
        aiMoveDirection = 0
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
                        stopAI()
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
            // Player idle walk animation
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                if !isAnimating && !isBlocking {
                    change = (change == X) ? "Walk" : X
                }
            }
            // Start AI
            startAI()
        }
        .onDisappear {
            stopAI()
        }
    }
}

#Preview {
    Boxing(rand: 0, xP: .constant(0))
}
