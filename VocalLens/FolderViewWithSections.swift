//
//  FolderViewWithSections.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 19/12/24.
//

import SwiftUI

struct FolderViewWithSections: View {
    let folderName: String
    @ObservedObject var recorder: AudioRecorder

    var body: some View {
        List {
            // Folder's All Recordings Section
            NavigationLink(destination: AllRecordingsView(folder: folderName, recorder: recorder)) {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                    Text("All Recordings")
                        .font(.headline)
                    Spacer()
                    Text("\(recorder.recordingsByFolder[folderName]?.count ?? 0)")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }

            // Folder's Recently Deleted Section
            NavigationLink(destination: DeletedRecordingsView(folder: folderName, recorder: recorder)) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                    Text("Recently Deleted")
                        .font(.headline)
                    Spacer()
                    Text("\(recorder.deletedRecordingsByFolder[folderName]?.count ?? 0)")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(folderName)
        .listStyle(InsetGroupedListStyle())
    }
}
