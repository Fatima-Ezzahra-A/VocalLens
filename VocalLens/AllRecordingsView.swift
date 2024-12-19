//
//  AllRecordingsView.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 13/12/24.
//

import SwiftUI
import AVFoundation
import UIKit

struct AllRecordingsView: View {
    let folder: String // Folder name
    @ObservedObject var recorder: AudioRecorder // Audio recorder instance

    @State private var isRecording = false
    @State private var isEditing = false
    @State private var selectedRecordings: Set<UUID> = [] // Tracks selected recordings for editing
    @State private var currentlyPlayingID: UUID? = nil // Tracks the currently playing recording
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
                            .onTapGesture {
                                if !isEditing { // Only toggle playback if not in edit mode
                                    togglePlayback(for: recording)
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }

            // Centered Record Button
            VStack {
                Spacer()
                if !isEditing {
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
            }

            // Edit Actions Fixed at Bottom
            if isEditing {
                VStack {
                    Spacer()
                    HStack {
                        // Share Button
                        Button(action: shareSelected) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }

                        Spacer()

                        // Delete Button
                        Button(action: deleteSelected) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(folder)
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
        HStack {
            // Play/Pause Button
            if !isEditing { // Show play/pause button only in normal mode
                Button(action: {
                    togglePlayback(for: recording)
                }) {
                    Image(systemName: recorder.isPlaying(url: recording.url) ? "pause.circle.fill" : "play.circle.fill")
                        .foregroundColor(recorder.isPlaying(url: recording.url) ? .green : .blue)
                        .font(.title)
                }
            }

            VStack(alignment: .leading) {
                // Waveform and Duration
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 40)
                        .overlay(
                            HStack {
                                Image(systemName: "waveform")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(recording.duration)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 8)
                        )
                }
                .padding(.bottom, 4)

                // Transcription Text
                Text(recording.transcription)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 8)

            Spacer()

            if isEditing {
                // Selection Checkbox
                Button(action: {
                    toggleSelection(recording.id)
                }) {
                    Image(systemName: selectedRecordings.contains(recording.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(selectedRecordings.contains(recording.id) ? .blue : .gray)
                }
            }
        }
        .padding(.vertical, 4)
        .background(isEditing && selectedRecordings.contains(recording.id) ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }

    // MARK: - Toggle Playback
    private func togglePlayback(for recording: Recording) {
        if recorder.isPlaying(url: recording.url) {
            recorder.stopPlayback()
            currentlyPlayingID = nil
        } else {
            recorder.playRecording(url: recording.url)
            currentlyPlayingID = recording.id
        }
    }

    // MARK: - Edit Buttons Logic
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
        // Collect the URLs of the selected recordings
        let selectedURLs = recorder.recordingsByFolder[folder]?
            .filter { selectedRecordings.contains($0.id) }
            .map { $0.url } ?? []

        guard !selectedURLs.isEmpty else {
            print("No recordings selected to share.")
            return
        }

        // Present the share sheet
        let activityVC = UIActivityViewController(activityItems: selectedURLs, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }
}
