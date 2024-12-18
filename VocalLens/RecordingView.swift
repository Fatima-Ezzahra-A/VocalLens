//
//  MainMenuView.swift.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 16/12/24.
//

import SwiftUI

struct RecordingView: View {
    @State private var newName: String
    @State private var isEditing: Bool = false

    var recording: Recording
    var onDelete: () -> Void
    var onPlay: () -> Void
    var onRename: (String) -> Void

    init(recording: Recording, onDelete: @escaping () -> Void, onPlay: @escaping () -> Void, onRename: @escaping (String) -> Void) {
        self.recording = recording
        self.onDelete = onDelete
        self.onPlay = onPlay
        self.onRename = onRename
        _newName = State(initialValue: recording.transcription)
    }

    var body: some View {
        HStack {
            // Play Button
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }

            //MARK: Editable Recording Name
            if isEditing {
                TextField("Rename", text: $newName, onCommit: {
                    onRename(newName)
                    isEditing = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text(recording.transcription)
                    .font(.subheadline)
                    .lineLimit(1)
                    .onTapGesture {
                        isEditing = true
                    }
            }

            Spacer()

            //MARK: Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 5)
    }
}
