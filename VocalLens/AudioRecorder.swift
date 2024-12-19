//
//  AudioRecorder.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 13/12/24.
//

import AVFoundation
import Foundation
import Speech

class AudioRecorder: NSObject, ObservableObject {
    @Published var folders: [String] = ["All Recordings", "Recently Deleted"] // Default folders
    @Published var recordingsByFolder: [String: [Recording]] = ["All Recordings": []]
    @Published var deletedRecordingsByFolder: [String: [Recording]] = ["Recently Deleted": []] // Separate deleted recordings by folder

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    @Published private(set) var currentlyPlayingURL: URL? // Tracks the currently playing recording

    // MARK: - Playback Status
    public func isPlaying(url: URL) -> Bool {
        return audioPlayer?.isPlaying == true && audioPlayer?.url == url
    }

    // MARK: - Add Folder
    public func addFolder(name: String) {
        guard !name.isEmpty, !folders.contains(name) else { return }
        folders.append(name)
        recordingsByFolder[name] = []
        deletedRecordingsByFolder[name] = [] // Initialize deleted recordings for the folder
    }

    // MARK: - Start Recording
    public func startRecording(to folder: String) {
        let recordingName = "Recording-\(Date().timeIntervalSince1970).m4a"
        let url = getDocumentsDirectory().appendingPathComponent(recordingName)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 48000,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            print("✅ Recording started: \(url)")
        } catch {
            print("❌ Error starting recording: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Recording
    public func stopRecording(to folder: String) {
        guard let recorder = audioRecorder else { return }
        recorder.stop()

        let url = recorder.url
        loadDuration(for: url) { duration in
            let newRecording = Recording(id: UUID(), url: url, transcription: "Transcribing...", duration: duration)
            DispatchQueue.main.async {
                if self.recordingsByFolder[folder] == nil {
                    self.recordingsByFolder[folder] = []
                }
                self.recordingsByFolder[folder]?.append(newRecording)
                self.transcribeAudio(url: url) { transcription in
                    if let index = self.recordingsByFolder[folder]?.firstIndex(where: { $0.id == newRecording.id }) {
                        self.recordingsByFolder[folder]?[index].transcription = transcription
                    }
                }
            }
        }
    }

    // MARK: - Play Recording
    public func playRecording(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            currentlyPlayingURL = url
            print("▶️ Playback started: \(url)")
        } catch {
            print("❌ Playback error: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Playback
    public func stopPlayback() {
        audioPlayer?.stop()
        currentlyPlayingURL = nil
        print("⏹️ Playback stopped.")
    }

    // MARK: - Delete Recording
    public func deleteRecording(from folder: String, recording: Recording) {
        if let index = recordingsByFolder[folder]?.firstIndex(where: { $0.id == recording.id }) {
            let deletedRecording = recordingsByFolder[folder]?.remove(at: index)
            if let deleted = deletedRecording {
                if folder == "All Recordings" {
                    // Add to shared Recently Deleted
                    deletedRecordingsByFolder["Recently Deleted"]?.append(deleted)
                } else {
                    // Add to folder-specific Recently Deleted
                    if deletedRecordingsByFolder[folder] == nil {
                        deletedRecordingsByFolder[folder] = []
                    }
                    deletedRecordingsByFolder[folder]?.append(deleted)
                }
            }
        }
    }

    // MARK: - Recover Recording
    public func recoverRecording(to folder: String, recording: Recording) {
        if folder == "All Recordings" {
            if let index = deletedRecordingsByFolder["Recently Deleted"]?.firstIndex(where: { $0.id == recording.id }) {
                let recoveredRecording = deletedRecordingsByFolder["Recently Deleted"]?.remove(at: index)
                if let recovered = recoveredRecording {
                    recordingsByFolder[folder]?.append(recovered)
                }
            }
        } else {
            if let index = deletedRecordingsByFolder[folder]?.firstIndex(where: { $0.id == recording.id }) {
                let recoveredRecording = deletedRecordingsByFolder[folder]?.remove(at: index)
                if let recovered = recoveredRecording {
                    recordingsByFolder[folder]?.append(recovered)
                }
            }
        }
    }

    // MARK: - Transcribe Audio
    private func transcribeAudio(url: URL, completion: @escaping (String) -> Void) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)

        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                completion(result.bestTranscription.formattedString)
            } else if let error = error {
                print("❌ Transcription error: \(error.localizedDescription)")
                completion("Transcription failed")
            }
        }
    }

    // MARK: - Load Duration
    private func loadDuration(for url: URL, completion: @escaping (String) -> Void) {
        let asset = AVURLAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)
                let formattedDuration = String(format: "%02d:%02d", Int(seconds) / 60, Int(seconds) % 60)
                completion(formattedDuration)
            } catch {
                print("❌ Error loading duration: \(error.localizedDescription)")
                completion("00:00")
            }
        }
    }

    // MARK: - Helper: Get Documents Directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
