//
//  SwiftUIView.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 13/12/24.
//

import SwiftUI

struct DeletedRecordingsView: View {
    let folder: String
    @ObservedObject var recorder: AudioRecorder

    var body: some View {
        List {
            ForEach(recorder.deletedRecordingsByFolder[folder] ?? []) { recording in
                VStack(alignment: .leading) {
                    Text(recording.transcription)
                    Text(recording.duration)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Recently Deleted")
    }
}
