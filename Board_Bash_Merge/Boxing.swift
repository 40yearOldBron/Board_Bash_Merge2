//
//  Boxing.swift
//  Board_Bash_Merge
//
//  Created by 64011955 on 4/22/26.
//
import SwiftUI
struct Boxing: View {
    let X = "Fighting x 12"
    let Y = "PounchFixed"
    let Z = "KickFixed"
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
    @State var isAnimating = false   // for punch/kick animations
    @State var isJumping = false     // ✅ separate jump control
    @State var moveTimer: Timer? = nil
    let minX: CGFloat = -150
    let maxX: CGFloat = 150
    let moveStep: CGFloat = 6
    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    /*
    if badDam <= 0 {
        win = true
    }
    */
    func playAnimation(_ imageName: String) {
        guard !isAnimating else { return }
        isAnimating = true
        change = imageName
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            change = X
            isAnimating = false
        }
    }
    func jump() {
        guard !isJumping else { return }
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
    func Damaged() -> Int {
        let value = Int.random(in: 3...15)
        rand = value
        return value
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
                .onReceive(countdownTimer) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timerFinished = true
                    }
                }
  /*
               .fullScreenCover(isPresented: $timerFinished) {
                    CheckersView()
                }
   */
            
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
            ///////////////////////////////////////////////////////////////////////
            Image(change)
                .frame(width: 100, height: 200)
                .scaleEffect(0.75)
                .offset(x: characterX, y: characterY) // ✅ uses Y
            /////////////////////////////////////////////////////////////////////
            
            Image(badChange)
                .frame(width: 100, height: 200.0)
                    .scaleEffect(0.75)
                    .offset(x: BcharacterX, y: BcharacterY)
            VStack {
                HStack {
                    Button("SP1") {}
                        .frame(width: 60, height: 40)
                        .background(Color.gray)
                        .offset(x: -95, y: 225)
                        .font(.largeTitle)
                        .opacity(0.08)
                    Button("SP2") {}
                        .frame(width: 60, height: 40)
                        .background(Color.gray)
                        .offset(x: -65, y: 225)
                        .font(.largeTitle)
                        .opacity(0.08)
                    Button("Jump") {
                        jump()
                        playAnimation(X)
                    }
                    .frame(width: 60, height: 90)
                    .background(Color.gray)
                    .offset(x: 100, y: 210)
                    .font(.largeTitle)
                    .opacity(0.08)
                }
            }
            HStack {
                Button("LeftRow") {}
                    .frame(width: 75, height: 75)
                    .background(Color.gray)
                    .padding(.trailing)
                    .padding(.top, 600)
                    .offset(x: 10, y: 7)
                    .font(.largeTitle)
                    .opacity(0.08)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in startMoving(direction: -1.5) }
                            .onEnded { _ in stopMoving() }
                    )
                Spacer()
                Button("RightRow") {}
                    .frame(width: 75, height: 75)
                    .background(Color.gray)
                    .padding(.trailing)
                    .padding(.top, 600)
                    .offset(x: -110, y: 7)
                    .font(.largeTitle)
                    .opacity(0.08)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in startMoving(direction: 1.5) }
                            .onEnded { _ in stopMoving() }
                    )
                Spacer()
            }
            Button("Kick") {
                playAnimation(Z)
            }
            .frame(width: 55, height: 100)
            .background(Color.gray)
            .padding(.trailing)
            .padding(.top, 600)
            .offset(x: 120, y: 7)
            .font(.largeTitle)
            .opacity(0.08)
            Spacer()
            Button("Punch") {
                playAnimation(Y)
            }
            .frame(width: 55, height: 100)
            .background(Color.gray)
            .padding(.trailing)
            .padding(.top, 600)
            .offset(x: 177, y: 7)
            .font(.largeTitle)
            .opacity(0.08)
            Spacer()
        }
    }
}
#Preview {
    Boxing(rand: 0, xP: .constant(0))
}
