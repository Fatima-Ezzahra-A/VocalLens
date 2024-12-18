//
//  FolderView.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 18/12/24.
//

import SwiftUI

struct FolderView: View {
    let folderName: String
    @ObservedObject var recorder: AudioRecorder

    var body: some View {
        List {
            NavigationLink(destination: AllRecordingsView(folder: folderName, recorder: recorder)) {
                Label("All Recordings", systemImage: "waveform")
            }
            NavigationLink(destination: DeletedRecordingsView(folder: folderName, recorder: recorder)) {
                Label("Recently Deleted", systemImage: "trash")
            }
        }
        .navigationTitle(folderName)
    }
}
