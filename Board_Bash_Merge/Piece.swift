//
//  Piece.swift
//  Board_Bash_Merge
//
//  Created by 64011955 on 5/15/26.
//
import Foundation

struct Piece: Identifiable, Codable {
    let id: UUID
    var row: Int
    var col: Int
    var isRed: Bool
    var isKing: Bool = false
}
