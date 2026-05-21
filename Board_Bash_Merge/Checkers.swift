import SwiftUI
import AVFAudio

struct CheckersView: View {

    @Environment(\.dismiss) var dismiss
    @State private var pieces: [Piece] = []
    @State private var selectedPieceID: UUID? = nil
    @State private var isRedTurn = true
    @State private var isMoving = false
    @State private var isMidCapture = false
    
    @State private var player: AVAudioPlayer?

    @State var timeRemaining = 60.0
    @State var timerFinished = false
    @State private var countdownTimer: Timer? = nil

    @State private var turnTimeRemaining = 10.00
    @State private var turnTimer: Timer? = nil

    @State private var gameOver = false
    @State private var playerWon = false

    var timeString: String {
        let m = Int(timeRemaining) / 60
        let s = Int(timeRemaining) % 60
        return String(format: "%d:%02d", m, s)
    }

    var turnTimeString: String {
        return String(format: "%.1f", turnTimeRemaining)
    }

    var body: some View {

        ZStack {

            Image("CheckersScreenBG")
                .resizable()
                .ignoresSafeArea()

            Text(timeString)
                .frame(width: 100, height: 100)
                .background(timeRemaining <= 10 ? Color.red : Color.black)
                .font(.largeTitle)
                .fontWeight(.black)
                .cornerRadius(30)
                .foregroundColor(.white)
                .offset(x: 130, y: -370)
                .fullScreenCover(isPresented: $timerFinished) {

                    Boxing(rand: 0, xP: .constant(0))
                        .onDisappear {

                            timeRemaining = 60
                            timerFinished = false

                            startTimer()
                            startTurnTimer()
                        }
                }

            VStack {

                Text(isRedTurn ? "Blue's Turn" : "Red's Turn")
                    .frame(width: 300, height: 180)
                    .background(Color.white)
                    .foregroundColor(isRedTurn ? .blue : .red)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .cornerRadius(30)
                    .offset(y: 300)

                Text(turnTimeString)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.black)
                    .offset(y: 230)
            }

            VStack {

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 8),
                    spacing: 0
                ) {

                    ForEach(0..<64) { index in

                        let row = index / 8
                        let col = index % 8

                        ZStack {

                            Rectangle()
                                .stroke(Color.black, lineWidth: 5)
                                .offset(y: 25)

                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color.white : Color.black)
                                .frame(width: 45, height: 45)
                                .offset(y: 26)

                            if let piece = pieceAt(row: row, col: col) {

                                Image(
                                    piece.isKing
                                    ? (piece.isRed ? "BlueKing" : "RedKing")
                                    : (piece.isRed ? "BlueHappyChecker" : "RedMadChecker")
                                )
                                .resizable()
                                .frame(width: 1, height: 1)
                                .scaleEffect(70)
                                .offset(y: 20)
                            }

                            if let selID = selectedPieceID,
                               let sel = pieces.first(where: { $0.id == selID }),
                               sel.row == row && sel.col == col {

                                Rectangle()
                                    .stroke(Color.green, lineWidth: 5)
                                    .offset(y: 25)
                            }
                        }
                        .onTapGesture {
                            handleTap(row: row, col: col)
                        }
                    }
                }
                .frame(width: 360, height: 375)
                .offset(x: 2, y: -20)
            }
        }
        .fullScreenCover(isPresented: $gameOver) {
            End(rand: playerWon ? 1 : 0, xP: .constant(0)) {
                gameOver = false
                dismiss()
            }
        }
        .onAppear {

            timeRemaining = 60
            timerFinished = false

            startTimer()
            startTurnTimer()

            loadGame()
        }
        .onDisappear {

            stopTimer()
            stopTurnTimer()
        }
    }

    func startTimer() {

        stopTimer()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in

            DispatchQueue.main.async {

                if timeRemaining > 0 {

                    timeRemaining -= 1

                } else {

                    timerFinished = true
                    stopTimer()
                }
            }
        }
    }

    func stopTimer() {

        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    func startTurnTimer() {

        stopTurnTimer()

        turnTimeRemaining = 10.00

        turnTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in

            DispatchQueue.main.async {

                if turnTimeRemaining > 0 {

                    turnTimeRemaining -= 0.01

                } else {

                    isRedTurn.toggle()
                    turnTimeRemaining = 10.00
                }
            }
        }
    }

    func resetTurnTimer() {
        turnTimeRemaining = 10.00
    }

    func stopTurnTimer() {

        turnTimer?.invalidate()
        turnTimer = nil
    }

    func checkForGameOver() {

        let redPieces = pieces.filter { $0.isRed }
        let bluePieces = pieces.filter { !$0.isRed }

        guard redPieces.isEmpty || bluePieces.isEmpty else { return }

        stopTimer()
        stopTurnTimer()

        playerWon = bluePieces.isEmpty
        gameOver = true
    }

    func loadGame() {

        if UserDefaults.standard.bool(forKey: "gameInProgress"),
           let data = UserDefaults.standard.data(forKey: "savedPieces"),
           let decoded = try? JSONDecoder().decode([Piece].self, from: data) {

            pieces = decoded
            isRedTurn = UserDefaults.standard.bool(forKey: "savedTurn")

        } else {

            setupBoard()
        }
    }

    func saveGame() {

        if let encoded = try? JSONEncoder().encode(pieces) {

            UserDefaults.standard.set(encoded, forKey: "savedPieces")
        }

        UserDefaults.standard.set(isRedTurn, forKey: "savedTurn")
        UserDefaults.standard.set(true, forKey: "gameInProgress")
    }

    func setupBoard() {

        pieces.removeAll()

        selectedPieceID = nil
        isRedTurn = true
        isMoving = false
        isMidCapture = false

        for row in 0..<3 {

            for col in 0..<8 where (row + col) % 2 == 1 {

                pieces.append(
                    Piece(
                        id: UUID(),
                        row: row,
                        col: col,
                        isRed: false
                    )
                )
            }
        }

        for row in 5..<8 {

            for col in 0..<8 where (row + col) % 2 == 1 {

                pieces.append(
                    Piece(
                        id: UUID(),
                        row: row,
                        col: col,
                        isRed: true
                    )
                )
            }
        }
    }

    func pieceAt(row: Int, col: Int) -> Piece? {

        pieces.first {
            $0.row == row && $0.col == col
        }
    }

    @discardableResult
    func movePiece(by id: UUID, toRow: Int, toCol: Int) -> Bool {

        guard let index = pieces.firstIndex(where: { $0.id == id }) else {
            return false
        }

        var board = pieces
        let piece = board[index]

        var didCapture = false

        if abs(toRow - piece.row) == 2 {

            let midRow = (piece.row + toRow) / 2
            let midCol = (piece.col + toCol) / 2

            if let capIdx = board.firstIndex(where: {
                $0.row == midRow && $0.col == midCol
            }) {

                board.remove(at: capIdx)
                didCapture = true
            }
        }

        if let newIdx = board.firstIndex(where: { $0.id == id }) {

            board[newIdx].row = toRow
            board[newIdx].col = toCol

            if (board[newIdx].isRed && toRow == 0) ||
               (!board[newIdx].isRed && toRow == 7) {

                board[newIdx].isKing = true
            }
        }

        pieces = board

        return didCapture
    }

    func isValidMove(from piece: Piece, toRow: Int, toCol: Int) -> Bool {

        guard toRow >= 0,
              toRow < 8,
              toCol >= 0,
              toCol < 8 else {
            return false
        }

        guard pieceAt(row: toRow, col: toCol) == nil else {
            return false
        }

        let rowDiff = toRow - piece.row
        let colDiff = abs(toCol - piece.col)

        if abs(rowDiff) == 1 && colDiff == 1 {

            if piece.isKing {
                return true
            }

            return piece.isRed
            ? rowDiff == -1
            : rowDiff == 1
        }

        if abs(rowDiff) == 2 && colDiff == 2 {

            if !piece.isKing {

                let allowedDirection = piece.isRed ? -1 : 1

                guard rowDiff / 2 == allowedDirection else {
                    return false
                }
            }

            let midRow = (piece.row + toRow) / 2
            let midCol = (piece.col + toCol) / 2

            if let enemy = pieceAt(row: midRow, col: midCol),
               enemy.isRed != piece.isRed {

                return true
            }
        }

        return false
    }

    func captureDestinations(for piece: Piece) -> [(Int, Int)] {

        let dirs: [(Int, Int)] = piece.isKing
        ? [(-1,-1),(-1,1),(1,-1),(1,1)]
        : piece.isRed
            ? [(-1,-1),(-1,1)]
            : [(1,-1),(1,1)]

        return dirs.compactMap {

            let endRow = piece.row + $0.0 * 2
            let endCol = piece.col + $0.1 * 2

            return isValidMove(
                from: piece,
                toRow: endRow,
                toCol: endCol
            )
            ? (endRow, endCol)
            : nil
        }
    }

    func canCaptureAgain(piece: Piece) -> Bool {
        !captureDestinations(for: piece).isEmpty
    }

    func handleTap(row: Int, col: Int) {

        guard !isMoving,
              isRedTurn else {
            return
        }

        if !isMidCapture {

            if let piece = pieceAt(row: row, col: col),
               piece.isRed {

                selectedPieceID = piece.id
                return
            }
        }

        guard let selID = selectedPieceID,
              let selected = pieces.first(where: { $0.id == selID }) else {
            return
        }

        guard isValidMove(
            from: selected,
            toRow: row,
            toCol: col
        ) else {
            return
        }

        if isMidCapture &&
            abs(row - selected.row) != 2 {
            return
        }

        isMoving = true

        let didCapture = movePiece(
            by: selID,
            toRow: row,
            toCol: col
        )

        resetTurnTimer()

        if didCapture,
           let updated = pieces.first(where: { $0.id == selID }),
           canCaptureAgain(piece: updated) {

            selectedPieceID = updated.id
            isMidCapture = true
            isMoving = false

            saveGame()
            checkForGameOver()
            return
        }

        isMidCapture = false
        selectedPieceID = nil
        isRedTurn = false
        isMoving = false

        saveGame()
        checkForGameOver()

        guard !gameOver else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            makeAIMove()
        }
    }

    func makeAIMove() {

        isMoving = true

        let cpuPieces = pieces.filter { !$0.isRed }

        var captureMoves: [(UUID, Int, Int)] = []
        var normalMoves: [(UUID, Int, Int)] = []

        for piece in cpuPieces {

            for dest in captureDestinations(for: piece) {
                captureMoves.append((piece.id, dest.0, dest.1))
            }
        }

        if captureMoves.isEmpty {

            for piece in cpuPieces {

                let dirs: [(Int, Int)] = piece.isKing
                ? [(-1,-1),(-1,1),(1,-1),(1,1)]
                : [(1,-1),(1,1)]

                for dir in dirs {

                    let r = piece.row + dir.0
                    let c = piece.col + dir.1

                    if isValidMove(from: piece, toRow: r, toCol: c) {
                        normalMoves.append((piece.id, r, c))
                    }
                }
            }
        }

        let candidates = captureMoves.isEmpty ? normalMoves : captureMoves

        guard let move = candidates.randomElement() else {

            isRedTurn = true
            isMoving = false
            return
        }

        let wasCapture = !captureMoves.isEmpty

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {

            movePiece(by: move.0, toRow: move.1, toCol: move.2)

            resetTurnTimer()

            saveGame()
            checkForGameOver()

            guard !gameOver else { return }

            if wasCapture,
               let movedPiece = pieces.first(where: { $0.id == move.0 }),
               canCaptureAgain(piece: movedPiece) {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    continueAICapture(pieceID: move.0)
                }

            } else {

                isRedTurn = true
                isMoving = false
            }
        }
    }

    func continueAICapture(pieceID: UUID) {

        guard let current = pieces.first(where: { $0.id == pieceID }) else {

            isRedTurn = true
            isMoving = false
            return
        }

        let dests = captureDestinations(for: current)

        guard let dest = dests.randomElement() else {

            isRedTurn = true
            isMoving = false

            saveGame()
            checkForGameOver()
            return
        }

        movePiece(by: current.id, toRow: dest.0, toCol: dest.1)

        resetTurnTimer()

        saveGame()
        checkForGameOver()

        guard !gameOver else { return }

        if let next = pieces.first(where: { $0.id == current.id }),
           canCaptureAgain(piece: next) {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                continueAICapture(pieceID: next.id)
            }

        } else {

            isRedTurn = true
            isMoving = false
        }
    }
}

#Preview {
    CheckersView()
}
