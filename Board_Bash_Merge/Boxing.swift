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

    // MARK: - Hitbox Visibility (debug toggle)
    @State private var showHitboxes = true

    // MARK: - AI State
    @State private var aiMoveTimer: Timer? = nil
    @State private var aiActionTimer: Timer? = nil
    @State private var aiIsAnimating = false
    @State private var aiIsBlocking = false
    @State private var aiMoveDirection: CGFloat = 0
    @State private var aiMoveTimer2: Timer? = nil

    let minX: CGFloat = -150
    let maxX: CGFloat = 150
    let moveStep: CGFloat = 6
    let aiCloseRange: CGFloat = 120

    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var distanceBetweenFighters: CGFloat {
        abs(characterX - BcharacterX)
    }

    // MARK: - Hitbox Rects (in world space, relative to character center)
    func playerBodyRect() -> CGRect {
        CGRect(x: characterX - 100, y: characterY - 40, width: 110, height: 150)
    }

    func aiBodyRect() -> CGRect {
        CGRect(x: BcharacterX + 25, y: BcharacterY - 40, width: 110, height: 150)
    }

    func playerPunchHitbox() -> CGRect {
        let facingRight = characterX < BcharacterX
        let xOffset: CGFloat = facingRight ? 50 : -20
        return CGRect(x: characterX + xOffset + 45, y: characterY, width: 60, height: 30)
    }

    func playerKickHitbox() -> CGRect {
        let facingRight = characterX < BcharacterX
        let xOffset: CGFloat = facingRight ? 20 : -60
        return CGRect(x: characterX + xOffset + 50, y: characterY + 50, width: 60, height: 30)
    }

    func aiPunchHitbox() -> CGRect {
        let facingLeft = BcharacterX > characterX
        let xOffset: CGFloat = facingLeft ? -55 : 20
        return CGRect(x: BcharacterX + xOffset + 30, y: BcharacterY, width: 60, height: 30)
    }

    func aiKickHitbox() -> CGRect {
        let facingLeft = BcharacterX > characterX
        let xOffset: CGFloat = facingLeft ? -60 : 20
        return CGRect(x: BcharacterX + xOffset + 40, y: BcharacterY + 45, width: 60, height: 30)
    }

    // MARK: - Hit Detection
    func checkPlayerHitOnAI(isKick: Bool) {
        let attackBox = isKick ? playerKickHitbox() : playerPunchHitbox()
        let targetBox = aiBodyRect()
        if attackBox.intersects(targetBox) {
            let dmg = isKick ? 12 : 8
            badDam = max(0, badDam - (aiIsBlocking ? dmg / 2 : dmg))
        }
    }

    func checkAIHitOnPlayer(isKick: Bool) {
        let attackBox = isKick ? aiKickHitbox() : aiPunchHitbox()
        let targetBox = playerBodyRect()
        if attackBox.intersects(targetBox) {
            let dmg = isKick ? 10 : 7
            goDam = max(0, goDam - (isBlocking ? dmg / 2 : dmg))
        }
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
        withAnimation(.easeOut(duration: 0.2)) { characterY -= 100 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.2)) { characterY += 100 }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            checkPlayerHitOnAI(isKick: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { canPunch = true }
    }

    func doKick() {
        guard canKick else { return }
        canKick = false
        playAnimation(Z)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            checkPlayerHitOnAI(isKick: true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { canKick = true }
    }

    // MARK: - AI Brain
    func startAI() {
        aiMoveTimer2 = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            guard aiMoveDirection != 0 else { return }
            BcharacterX = min(max(BcharacterX + aiMoveDirection * 4, minX), maxX)
        }
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
            let roll = Int.random(in: 0...99)
            switch roll {
            case 0...39: aiDoAttack()
            case 40...64: aiDoBlock()
            case 65...84:
                let dodgeDir: CGFloat = BcharacterX > characterX ? 1 : -1
                aiMoveDirection = dodgeDir
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.5)) {
                    aiMoveDirection = 0
                }
            default: aiMoveDirection = 0
            }
        } else {
            let roll = Int.random(in: 0...99)
            switch roll {
            case 0...59:
                aiMoveDirection = BcharacterX > characterX ? -1 : 1
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.3...0.7)) {
                    aiMoveDirection = 0
                }
            case 60...84:
                aiMoveDirection = Bool.random() ? 1 : -1
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.2...0.5)) {
                    aiMoveDirection = 0
                }
            default: aiMoveDirection = 0
            }
        }
    }

    func aiDoAttack() {
        guard !aiIsAnimating && !aiIsBlocking else { return }
        let isKick = !Bool.random()
        let animName = isKick ? "badKick" : "badPunch"
        playAIAnimation(animName)
        let hitDelay: Double = isKick ? 0.25 : 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + hitDelay) {
            checkAIHitOnPlayer(isKick: isKick)
        }
    }

    func aiDoBlock() {
        guard !aiIsAnimating else { return }
        aiIsBlocking = true
        badChange = "badBlock"
        let blockDur = Double.random(in: 0.4...1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + blockDur) {
            aiIsBlocking = false
            badChange = "badStance"
        }
    }

    func stopAI() {
        aiMoveTimer?.invalidate(); aiMoveTimer = nil
        aiMoveTimer2?.invalidate(); aiMoveTimer2 = nil
        aiActionTimer?.invalidate(); aiActionTimer = nil
        aiMoveDirection = 0
    }

    // MARK: - Hitbox View Helper
    @ViewBuilder
    func hitboxOverlay(rect: CGRect, color: Color) -> some View {
        color.opacity(0.45)
            .frame(width: rect.width, height: rect.height)
            .border(color, width: 2)
            .offset(x: rect.midX, y: rect.midY)
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
                .fullScreenCover(isPresented: $timerFinished) {
                    CheckersView()
                        .onDisappear {
                            timeRemaining = 30
                            timerFinished = false
                        }
                }

            // HEALTH
            Text("\(badDam)")
                .background(Color.white)
                .font(.largeTitle).fontWeight(.bold)
                .foregroundColor(.green)
                .offset(x: 155, y: -335)

            Text("\(goDam)")
                .background(Color.white)
                .font(.largeTitle).fontWeight(.bold)
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

            // MARK: - HITBOXES
            if showHitboxes {
                // Player body hitbox
                hitboxOverlay(rect: playerBodyRect(), color: .red)
                // Player attack hitboxes
                if change == Y {
                    hitboxOverlay(rect: playerPunchHitbox(), color: .orange)
                }
                if change == Z {
                    hitboxOverlay(rect: playerKickHitbox(), color: .orange)
                }
                // AI body hitbox
                hitboxOverlay(rect: aiBodyRect(), color: Color(red: 1, green: 0.2, blue: 0.2))
                // AI attack hitboxes
                if badChange == "badPunch" {
                    hitboxOverlay(rect: aiPunchHitbox(), color: .orange)
                }
                if badChange == "badKick" {
                    hitboxOverlay(rect: aiKickHitbox(), color: .orange)
                }
            }

            // DEBUG TOGGLE
            Button(showHitboxes ? "Hide Hitboxes" : "Show Hitboxes") {
                showHitboxes.toggle()
            }
            .padding(6)
            .background(Color.black.opacity(0.5))
            .foregroundColor(.white)
            .cornerRadius(8)
            .offset(x: 0, y: -280)

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

                    Text("Jump")
                        .frame(width: 60, height: 90)
                        .background(Color.gray)
                        .offset(x: 100, y: 210)
                        .opacity(0.08)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if pressStartTime == nil { pressStartTime = Date() }
                                    if let start = pressStartTime,
                                       Date().timeIntervalSince(start) > 0.25,
                                       !isBlocking, canBlock {
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
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { canBlock = true }
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
            Button("Kick") { doKick() }
                .frame(width: 55, height: 100)
                .background(canKick ? Color.gray : Color.red)
                .offset(x: 120, y: 300)
                .opacity(0.08)

            Button("Punch") { doPunch() }
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
            startAI()
        }
        .onDisappear { stopAI() }
    }
}

#Preview {
    Boxing(rand: 0, xP: .constant(0))
}
