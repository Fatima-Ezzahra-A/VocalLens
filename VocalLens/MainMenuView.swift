//
//  MainMenuView.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 17/12/24.
//

import SwiftUI

struct MainMenuView: View {
    @StateObject var recorder = AudioRecorder()
    @State private var newFolderName = ""
    @State private var showAddFolderAlert = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Folders")) {
                    ForEach(recorder.folders, id: \.self) { folder in
                        NavigationLink(destination: FolderView(folderName: folder, recorder: recorder)) {
                            Label(folder, systemImage: "folder")
                        }
                    }
                }
            }
            .navigationTitle("Voice Memos")
            .toolbar {
                Button(action: { showAddFolderAlert = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
            .alert("Add New Folder", isPresented: $showAddFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Add") {
                    recorder.addFolder(name: newFolderName)
                    newFolderName = ""
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
