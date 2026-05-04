import SwiftUI

struct CheckersView: View {
    
    // 🧠 GAME STATE
    @State private var pieces: [Piece] = []
    @State private var selectedPieceID: UUID? = nil
    @State private var isRedTurn = true
    @State var moveTimer: Timer? = nil
    @State var timeRemaining = 30.0
    @State var timerFinished = false
    
    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            
            Image("CheckersScreenBG")
                .resizable()
                .ignoresSafeArea()
            
            Text(timeString)
                .frame(width:100, height:100)
                .background(timeRemaining <= 5 ? .red: .black)
                .font(.largeTitle)
                .fontWeight(.black)
                .cornerRadius(30)
                .foregroundColor(.white)
                .offset(x: 130, y: -370)
                .onReceive(countdownTimer) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timerFinished = true
                    }
                }
            
            Text(isRedTurn ? "Blue's Turn" : "Red's Turn")
                .frame(width:300, height:180)
                .background(Color.white)
                .foregroundColor(isRedTurn ? .blue: .red)
                .font(.largeTitle)
                .fontWeight(.black)
                .dynamicTypeSize(.xxxLarge)
                .cornerRadius(30)
                .offset(x:0, y:300)
            
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
                                .offset(x:0, y:25)
                            
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color.white : Color.black)
                                .frame(width:45, height: 45)
                                .offset(x:0,y:26)
                            
                            if let piece = pieceAt(row: row, col: col) {
                                Image(
                                    piece.isKing
                                    ? (piece.isRed ? "BlueKing" : "RedKing")
                                    : (piece.isRed ? "BlueHappyChecker" : "RedMadChecker")
                                )
                                    .resizable()
                                    .frame(width: 1, height:1)
                                    .scaleEffect(70)
                                    .offset(x:0, y:20)
                            }
                            
                            if let selectedID = selectedPieceID,
                               let selected = pieces.first(where: { $0.id == selectedID }),
                               selected.row == row && selected.col == col {
                               
                                Rectangle()
                                    .stroke(Color.green, lineWidth: 5)
                                    .offset(x:0, y:25)
                            }
                        }
                        .onTapGesture {
                            handleTap(row: row, col: col)
                        }
                    }
                }
                .frame(width: 360, height: 375)
                .offset(x:2,y:-20)
            }
        }
        .onAppear {
            setupBoard()
        }
    }
    
    struct Piece: Identifiable {
        let id = UUID()
        var row: Int
        var col: Int
        var isRed: Bool
        var isKing: Bool = false
    }
    
    func setupBoard() {
        pieces.removeAll()
        
        for row in 0..<3 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    pieces.append(Piece(row: row, col: col, isRed: false))
                }
            }
        }
        
        for row in 5..<8 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    pieces.append(Piece(row: row, col: col, isRed: true))
                }
            }
        }
    }
    
    func pieceAt(row: Int, col: Int) -> Piece? {
        pieces.first { $0.row == row && $0.col == col }
    }
    
    func handleTap(row: Int, col: Int) {
        
        if let piece = pieceAt(row: row, col: col),
           piece.isRed == isRedTurn {
            selectedPieceID = piece.id
            return
        }
        
        guard let selectedID = selectedPieceID,
              let selected = pieces.first(where: { $0.id == selectedID }) else { return }
        
        if isValidMove(from: selected, toRow: row, toCol: col) {
            
            let wasCapture = abs(row - selected.row) == 2
            
            movePiece(by: selectedID, toRow: row, toCol: col)
            
            if let updated = pieces.first(where: { $0.id == selectedID }),
               wasCapture && canCaptureAgain(piece: updated) {
                selectedPieceID = updated.id
                return
            }
            
            isRedTurn.toggle()
        }
        
        selectedPieceID = nil
    }
    
    // 🔥 FIXED: no backward capture for normal pieces
    func isValidMove(from piece: Piece, toRow: Int, toCol: Int) -> Bool {
        
        if pieceAt(row: toRow, col: toCol) != nil { return false }
        
        let rowDiff = toRow - piece.row
        let colDiff = abs(toCol - piece.col)
        
        if abs(rowDiff) == 1 && colDiff == 1 {
            if piece.isKing { return true }
            return piece.isRed ? rowDiff == -1 : rowDiff == 1
        }
        
        if abs(rowDiff) == 2 && colDiff == 2 {
            
            if !piece.isKing {
                if piece.isRed && rowDiff != -2 { return false }
                if !piece.isRed && rowDiff != 2 { return false }
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
    

    func canCaptureAgain(piece: Piece) -> Bool {
        
        let directions = piece.isKing
            ? [(-1,-1), (-1,1), (1,-1), (1,1)]
            : piece.isRed
                ? [(-1,-1), (-1,1)]
                : [(1,-1), (1,1)]
        
        for dir in directions {
            let midRow = piece.row + dir.0
            let midCol = piece.col + dir.1
            
            let endRow = piece.row + dir.0 * 2
            let endCol = piece.col + dir.1 * 2
            
            if endRow < 0 || endRow > 7 || endCol < 0 || endCol > 7 {
                continue
            }
            
            if let enemy = pieceAt(row: midRow, col: midCol),
               enemy.isRed != piece.isRed,
               pieceAt(row: endRow, col: endCol) == nil {
                return true
            }
        }
        
        return false
    }
    
    func movePiece(by id: UUID, toRow: Int, toCol: Int) {
        
        guard let index = pieces.firstIndex(where: { $0.id == id }) else { return }
        
        let piece = pieces[index]
        let rowDiff = abs(toRow - piece.row)
        
        if rowDiff == 2 {
            let midRow = (piece.row + toRow) / 2
            let midCol = (piece.col + toCol) / 2
            
            if let capturedIndex = pieces.firstIndex(where: {
                $0.row == midRow && $0.col == midCol
            }) {
                pieces.remove(at: capturedIndex)
            }
        }
        
        guard let newIndex = pieces.firstIndex(where: { $0.id == id }) else { return }
        
        pieces[newIndex].row = toRow
        pieces[newIndex].col = toCol
        
        if (pieces[newIndex].isRed && toRow == 0) ||
           (!pieces[newIndex].isRed && toRow == 7) {
            pieces[newIndex].isKing = true
        }
    }
}

#Preview {
    CheckersView()
}
