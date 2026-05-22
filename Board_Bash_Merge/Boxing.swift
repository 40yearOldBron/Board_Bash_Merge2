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
    @State var round = 1
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

    @State private var countdownTimerRef: Timer? = nil
    @State private var showHitboxes = true

    @State private var aiMoveTimer: Timer? = nil
    @State private var aiActionTimer: Timer? = nil
    @State private var aiIsAnimating = false
    @State private var aiIsBlocking = false
    @State private var aiMoveDirection: CGFloat = 0
    @State private var aiMoveTimer2: Timer? = nil

    @State private var gameOver = false
    @State private var playerWon = false

    let minX: CGFloat = -150
    let maxX: CGFloat = 150
    let moveStep: CGFloat = 6
    let aiCloseRange: CGFloat = 120

    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var distanceBetweenFighters: CGFloat {
        abs(characterX - BcharacterX)
    }

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

    func checkPlayerHitOnAI(isKick: Bool) {

        let attackBox = isKick ? playerKickHitbox() : playerPunchHitbox()
        let targetBox = aiBodyRect()

        if attackBox.intersects(targetBox) {

            let dmg = isKick ? 12 : 8

            badDam = max(0, badDam - (aiIsBlocking ? dmg / 2 : dmg))

            checkForGameOver()
        }
    }

    func checkAIHitOnPlayer(isKick: Bool) {

        let attackBox = isKick ? aiKickHitbox() : aiPunchHitbox()
        let targetBox = playerBodyRect()

        if attackBox.intersects(targetBox) {

            let dmg = isKick ? 10 : 7

            goDam = max(0, goDam - (isBlocking ? dmg / 2 : dmg))

            checkForGameOver()
        }
    }

    func checkForGameOver() {

        if badDam <= 0 {

            playerWon = true
            gameOver = true

            stopCountdown()
            stopAI()
        }

        if goDam <= 0 {

            playerWon = false
            gameOver = true

            stopCountdown()
            stopAI()
        }
    }

    func playSound(_ name: String, ext: String = "mp3") {

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }

        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }

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

    func doPunch() {

        guard canPunch else { return }

        canPunch = false

        playAnimation(Y)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            checkPlayerHitOnAI(isKick: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            canPunch = true
        }
    }

    func doKick() {

        guard canKick else { return }

        canKick = false

        playAnimation(Z)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            checkPlayerHitOnAI(isKick: true)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            canKick = true
        }
    }

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

            case 0...39:
                aiDoAttack()

            case 40...64:
                aiDoBlock()

            default:
                aiMoveDirection = 0
            }

        } else {

            aiMoveDirection = BcharacterX > characterX ? -1 : 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                aiMoveDirection = 0
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

        aiMoveTimer?.invalidate()
        aiMoveTimer2?.invalidate()
        aiActionTimer?.invalidate()

        aiMoveDirection = 0
    }

    func startCountdown() {

        countdownTimerRef?.invalidate()

        countdownTimerRef = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in

            if timeRemaining > 0 {

                timeRemaining -= 1

            } else {

                timerFinished = true

                stopCountdown()
            }
        }
    }

    func stopCountdown() {

        countdownTimerRef?.invalidate()
        countdownTimerRef = nil
    }

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

            Text(timeString)
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(timeRemaining <= 5 ? .red : .white)
                .offset(x: 0, y: -335)

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

            Image(badChange)
                .frame(width: 100, height: 200)
                .scaleEffect(0.75)
                .offset(x: BcharacterX, y: BcharacterY)

            Image(change)
                .frame(width: 100, height: 200)
                .scaleEffect(0.75)
                .offset(x: characterX, y: characterY)

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

            timeRemaining = 30

            startCountdown()
            startAI()
        }
        .onDisappear {

            stopCountdown()
            stopAI()
        }
        .fullScreenCover(isPresented: $gameOver) {

            End(rand: playerWon ? 1 : 0, xP: $xP)
        }
    }
}

#Preview {

    Boxing(rand: 0, xP: .constant(0))
}
