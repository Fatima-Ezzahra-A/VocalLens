//
//  MainMenuView.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 17/12/24.
//

import SwiftUI

struct MainMenuView: View {
    @State private var newFolderName = "" // Holds the name for a new folder
    @State private var showAddFolderAlert = false // Toggles the folder creation alert

    @StateObject var recorder = AudioRecorder() // Manages recordings

    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Main All Recordings Section
                    NavigationLink(destination: AllRecordingsView(folder: "All Recordings", recorder: recorder)) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(.blue)
                            Text("All Recordings")
                                .font(.headline)
                            Spacer()
                            Text("\(recorder.recordingsByFolder["All Recordings"]?.count ?? 0)") // Display total number of recordings
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }

                    // Main Recently Deleted Section
                    NavigationLink(destination: DeletedRecordingsView(folder: "Recently Deleted", recorder: recorder)) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Recently Deleted")
                                .font(.headline)
                            Spacer()
                            Text("\(recorder.deletedRecordingsByFolder["Recently Deleted"]?.count ?? 0)") // Display total number of deleted recordings
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }

                    // Dynamic Folders Section
                    if !recorder.folders.isEmpty {
                        Section(header: Text("MY FOLDERS").font(.subheadline)) {
                            ForEach(recorder.folders.filter { $0 != "All Recordings" && $0 != "Recently Deleted" }, id: \.self) { folderName in
                                NavigationLink(destination: FolderViewWithSections(folderName: folderName, recorder: recorder)) {
                                    HStack {
                                        Image(systemName: "folder")
                                            .foregroundColor(.blue)
                                        Text(folderName)
                                            .font(.headline)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                Spacer()

                // Add Folder Button
                HStack {
                    Spacer()
                    Button(action: {
                        showAddFolderAlert.toggle() // Show the alert for entering a custom folder name
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
            .navigationTitle("VocalLens")
            .alert("Add New Folder", isPresented: $showAddFolderAlert, actions: {
                TextField("Folder name", text: $newFolderName) // TextField for folder name input
                Button("Add", action: {
                    if !newFolderName.isEmpty && !recorder.folders.contains(newFolderName) {
                        recorder.addFolder(name: newFolderName) // Add the new folder with the custom name
                        newFolderName = "" // Reset the folder name field
                    }
                })
                Button("Cancel", role: .cancel, action: {
                    newFolderName = "" // Reset the folder name if canceled
                })
            }, message: {
                Text("Enter a name for the new folder.")
            })
        }
    }
}
