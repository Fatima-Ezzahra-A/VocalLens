//
//  AudioRecorder.swift
//  VocalLens
//
//  Created by aazzouz fatima ezzahra on 13/12/24.
//


import Foundation
import AVFoundation
import Speech

class AudioRecorder: ObservableObject {
    @Published var folders: [String] = []  // User-created folders
    @Published var recordingsByFolder: [String: [Recording]] = [:]
    @Published var deletedRecordingsByFolder: [String: [Recording]] = [:]
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var currentlyPlayingURL: URL?
    
    // MARK: - Public Playback Status
    func isPlaying(url: URL) -> Bool {
        return audioPlayer?.isPlaying == true && audioPlayer?.url == url
    }

    // MARK: - Add Folder
    func addFolder(name: String) {
        guard !name.isEmpty, !folders.contains(name) else { return }
        folders.append(name)
        recordingsByFolder[name] = []
        deletedRecordingsByFolder[name] = []
    }
    
    // MARK: - Start Recording
    func startRecording(to folder: String) {
        let recordingName = "Recording-\(Date().timeIntervalSince1970).m4a"
        let url = getDocumentsDirectory().appendingPathComponent(recordingName)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless), // High-quality format
            AVSampleRateKey: 48000, // High sample rate
            AVNumberOfChannelsKey: 2, // Stereo recording
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            print("✅ Recording started: \(url)")
        } catch {
            print("❌ Error starting recording: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Recording
    func stopRecording(to folder: String) {
        guard let recorder = audioRecorder else { return }
        recorder.stop()

        let url = recorder.url
        loadDuration(for: url) { duration in
            let newRecording = Recording(id: UUID(), url: url, transcription: "Transcribing...", duration: duration)
            DispatchQueue.main.async {
                self.recordingsByFolder[folder]?.append(newRecording)
                self.transcribeAudio(url: url) { transcription in
                    if let index = self.recordingsByFolder[folder]?.firstIndex(where: { $0.id == newRecording.id }) {
                        self.recordingsByFolder[folder]?[index].transcription = transcription
                    }
                }
            }
        }
    }
    
    // MARK: - Toggle Playback
    func togglePlayback(for url: URL) {
        if isPlaying(url: url) {
            stopPlayback()
        } else {
            startPlayback(url: url)
        }
    }
    
    private func startPlayback(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            currentlyPlayingURL = url
            print("▶️ Playback started: \(url)")
        } catch {
            print("❌ Playback error: \(error.localizedDescription)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        currentlyPlayingURL = nil
        print("⏹️ Playback stopped.")
    }
    
    // MARK: - Delete Recording
    func deleteRecording(from folder: String, recording: Recording) {
        if let index = recordingsByFolder[folder]?.firstIndex(where: { $0.id == recording.id }) {
            let deletedRecording = recordingsByFolder[folder]?.remove(at: index)
            if let deleted = deletedRecording {
                deletedRecordingsByFolder[folder]?.append(deleted)
            }
        }
    }
    
    // MARK: - Recover Recording
    func recoverRecording(to folder: String, recording: Recording) {
        if let index = deletedRecordingsByFolder[folder]?.firstIndex(where: { $0.id == recording.id }) {
            let recoveredRecording = deletedRecordingsByFolder[folder]?.remove(at: index)
            if let recovered = recoveredRecording {
                recordingsByFolder[folder]?.append(recovered)
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
                completion("❌ Transcription failed: \(error.localizedDescription)")
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
