//
//  AllRecordingsView.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 13/12/24.
//

import SwiftUI
import AVFoundation

struct AllRecordingsView: View {
    let folder: String
    @ObservedObject var recorder: AudioRecorder
    @State private var isRecording = false
    @State private var isEditing = false
    @State private var selectedRecordings: Set<UUID> = []
    @State private var searchText = ""

    var filteredRecordings: [Recording] {
        let recordings = recorder.recordingsByFolder[folder] ?? []
        if searchText.isEmpty {
            return recordings
        } else {
            return recordings.filter { $0.transcription.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        ZStack {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()

                // Recordings List
                List {
                    ForEach(filteredRecordings) { recording in
                        recordingRow(recording)
                    }
                }
                .listStyle(PlainListStyle())
            }

            // Centered Record Button
            VStack {
                Spacer()
                Button(action: {
                    if isRecording {
                        recorder.stopRecording(to: folder)
                    } else {
                        recorder.startRecording(to: folder)
                    }
                    isRecording.toggle()
                }) {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .foregroundColor(.white)
                                .font(.title)
                        )
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30)
            }

            // Edit Actions
            if isEditing {
                editButtons
            }
        }
        .navigationTitle("All Recordings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
                selectedRecordings.removeAll()
            }
        )
    }

    // MARK: - Recording Row
    private func recordingRow(_ recording: Recording) -> some View {
        VStack(alignment: .leading) {
            HStack {
                // Play/Stop Button
                Button(action: {
                    recorder.togglePlayback(for: recording.url)
                }) {
                    Image(systemName: recorder.isPlaying(url: recording.url) ? "stop.circle.fill" : "play.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                }

                // Waveform Placeholder and Duration
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 40)
                    .overlay(
                        HStack {
                            Image(systemName: "waveform") // Replace with animated waveform if needed
                                .foregroundColor(.blue)
                            Spacer()
                            Text(recording.duration)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 8)
                    )
            }

            // Transcription Text
            Text(recording.transcription)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    // Edit Buttons
    private var editButtons: some View {
        HStack {
            Button(action: { shareSelected() }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            Spacer()
            Button(action: { deleteSelected() }) {
                Image(systemName: "trash")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    // MARK: - Helper Methods
    private func toggleSelection(_ id: UUID) {
        if selectedRecordings.contains(id) {
            selectedRecordings.remove(id)
        } else {
            selectedRecordings.insert(id)
        }
    }

    private func deleteSelected() {
        for id in selectedRecordings {
            if let recording = recorder.recordingsByFolder[folder]?.first(where: { $0.id == id }) {
                recorder.deleteRecording(from: folder, recording: recording)
            }
        }
        selectedRecordings.removeAll()
    }

    private func shareSelected() {
        // Logic for sharing files can be added here
    }
}
