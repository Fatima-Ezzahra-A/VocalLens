//
//  Recording.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 17/12/24.
//
import Foundation

struct Recording: Identifiable {
    let id: UUID
    let url: URL
    var transcription: String
    let duration: String
}
