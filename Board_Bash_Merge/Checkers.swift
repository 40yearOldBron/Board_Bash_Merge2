//
//  Checkers.swift
//  Board_Bash_Merge
//
//  Created by 64011955 on 4/22/26.
//
import SwiftUI
struct CheckersView: View {
    
    // 🧠 GAME STATE
    @State private var pieces: [Piece] = []
    @State private var selectedPiece: Piece? = nil
    @State private var isRedTurn = true
    
    var body: some View {
        ZStack {
            
            //BACKGROUND
            Image("CheckersScreenBG")
                .resizable()
                .ignoresSafeArea()
            
            VStack {
                
                Text(isRedTurn ? "Blue's Turn" : "Red's Turn")
                    .font(.title)
                    .foregroundColor(.white)
                
                //BOARD
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 8),
                    spacing: 0
                ) {
                    
                    ForEach(0..<64) { index in
                        let row = index / 8
                        let col = index % 8
                        
                        ZStack {
                            
                            //TILE COLOR
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color.white : Color.black)
                                .frame(width:45, height: 45)
                            
                            //PIECES
                            if let piece = pieceAt(row: row, col: col) {
                                
                                Image(piece.isRed ? "BlueHappyChecker" : "RedMadChecker")
                                    .resizable()
                                    .frame(width: 1, height:1)
                                    .scaleEffect(70)
                                    .offset(x:0, y:-5)
                                 
                            }
                            
                            //HIGHLIGHT
                            if selectedPiece?.row == row && selectedPiece?.col == col {
                                Rectangle()
                                    .stroke(Color.pink, lineWidth: 3)
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
    
       
    
    //PIECE MODEL
    struct Piece: Identifiable {
        let id = UUID()
        var row: Int
        var col: Int
        var isRed: Bool
        var isKing: Bool = false
    }
    
    //SETUP BOARD
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
    
    // FIND PIECE
    func pieceAt(row: Int, col: Int) -> Piece? {
        pieces.first { $0.row == row && $0.col == col }
    }
    
    //TAP
    func handleTap(row: Int, col: Int) {
        
        // Select piece
        if let piece = pieceAt(row: row, col: col),
           piece.isRed == isRedTurn {
            selectedPiece = piece
            return
        }
        
        // Move piece
        guard let selected = selectedPiece else { return }
        
        if isValidMove(from: selected, toRow: row, toCol: col) {
            movePiece(selected, toRow: row, toCol: col)
            isRedTurn.toggle()
        }
        
        selectedPiece = nil
    }
    
    //VALID MOVE
    func isValidMove(from piece: Piece, toRow: Int, toCol: Int) -> Bool {
        
        if pieceAt(row: toRow, col: toCol) != nil { return false }
        
        let rowDiff = toRow - piece.row
        let colDiff = abs(toCol - piece.col)
        
        // Normal move
        if abs(rowDiff) == 1 && colDiff == 1 {
            if piece.isKing { return true }
            return piece.isRed ? rowDiff == -1 : rowDiff == 1
        }
        
        // Jump
        if abs(rowDiff) == 2 && colDiff == 2 {
            let midRow = (piece.row + toRow) / 2
            let midCol = (piece.col + toCol) / 2
            
            if let enemy = pieceAt(row: midRow, col: midCol),
               enemy.isRed != piece.isRed {
                return true
            }
        }
        
        return false
    }
    
    //  MOVE PIECE
    func movePiece(_ piece: Piece, toRow: Int, toCol: Int) {
        
        guard let index = pieces.firstIndex(where: { $0.id == piece.id }) else { return }
        
        let rowDiff = abs(toRow - piece.row)
        
        // Remove captured piece
        if rowDiff == 2 {
            let midRow = (piece.row + toRow) / 2
            let midCol = (piece.col + toCol) / 2
            
            pieces.removeAll {
                $0.row == midRow && $0.col == midCol
            }
        }
        
        // Move
        pieces[index].row = toRow
        pieces[index].col = toCol
        
        // King
        if (pieces[index].isRed && toRow == 0) ||
           (!pieces[index].isRed && toRow == 7) {
            pieces[index].isKing = true
        }
    }
}
#Preview {
    CheckersView()
}
