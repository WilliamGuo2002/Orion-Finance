import Foundation
import AVFoundation
import UIKit

/// Manages a real-time WebSocket session with Gemini Live API
@MainActor
class GeminiLiveService: NSObject, ObservableObject {
    // MARK: - Published state
    @Published var isConnected = false
    @Published var isAISpeaking = false
    @Published var transcript = ""
    @Published var aiTranscript = ""
    @Published var errorMessage: String?

    // MARK: - Audio engine (input)
    private var audioEngine = AVAudioEngine()

    // MARK: - Audio player (output)
    private var playerEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private let outputSampleRate: Double = 24000
    private var outputFormat: AVAudioFormat!

    // MARK: - WebSocket
    private var webSocket: URLSessionWebSocketTask?
    private var wsDelegate: WSDelegate?
    private var withVideo = false

    // MARK: - Video
    private var videoTimer: Timer?
    var captureFrameHandler: (() -> Data?)?

    // MARK: - Callback
    var onSessionEnd: (() -> Void)?

    override init() {
        super.init()
        outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: outputSampleRate, channels: 1, interleaved: true)
    }

    // MARK: - Connect
    func connect(withVideo: Bool = false) {
        guard !isConnected, webSocket == nil else { return }
        self.withVideo = withVideo
        errorMessage = nil
        transcript = ""
        aiTranscript = ""

        let endpoint = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=\(APIKeys.gemini)"
        guard let url = URL(string: endpoint) else {
            errorMessage = "Invalid endpoint URL"
            return
        }

        // Create delegate to handle WebSocket open/close
        wsDelegate = WSDelegate(
            onOpen: { [weak self] in
                Task { @MainActor in
                    self?.onWebSocketOpened()
                }
            },
            onClose: { [weak self] reason in
                Task { @MainActor in
                    self?.errorMessage = reason
                    self?.isConnected = false
                    self?.onSessionEnd?()
                }
            }
        )

        let session = URLSession(configuration: .default, delegate: wsDelegate, delegateQueue: nil)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()

        // Start receive loop immediately (it will wait for connection)
        receiveMessage()
    }

    // Called when WebSocket connection is established
    private func onWebSocketOpened() {
        print("WebSocket opened, sending setup...")
        sendSetup()
    }

    // MARK: - Disconnect
    func disconnect() {
        videoTimer?.invalidate()
        videoTimer = nil
        stopAudioInput()
        stopAudioOutput()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        wsDelegate = nil
        isConnected = false
        isAISpeaking = false
    }

    // MARK: - Setup message
    private func sendSetup() {
        // Use the correct Live API model
        let setup: [String: Any] = [
            "setup": [
                "model": "models/gemini-2.0-flash-live-001",
                "generationConfig": [
                    "responseModalities": ["AUDIO"],
                    "speechConfig": [
                        "voiceConfig": [
                            "prebuiltVoiceConfig": [
                                "voiceName": "Aoede"
                            ]
                        ]
                    ]
                ] as [String: Any],
                "systemInstruction": [
                    "parts": [["text": """
                        You are Orion, an AI financial assistant built into the Orion Finance app. \
                        You specialize in stock market analysis, investment advice, and financial news. \
                        Be concise, helpful, and conversational. You can answer general questions too. \
                        Always keep the name "Orion" and "Orion Finance" unchanged. \
                        Detect the language the user is speaking in, and always reply in that same language.
                        """]]
                ],
                "realtimeInputConfig": [
                    "automaticActivityDetection": [
                        "disabled": false
                    ] as [String: Any],
                    "activityHandling": "START_OF_ACTIVITY_INTERRUPTS",
                    "turnCoverage": "TURN_INCLUDES_ALL_INPUT"
                ] as [String: Any],
                "inputAudioTranscription": [String: Any](),
                "outputAudioTranscription": [String: Any]()
            ] as [String: Any]
        ]

        sendJSON(setup)
    }

    // MARK: - Audio Input (Microphone → Server)
    func startAudioInput() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio session error: \(error)")
            return
        }

        let inputNode = audioEngine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true) else { return }
        guard let converter = AVAudioConverter(from: hardwareFormat, to: targetFormat) else {
            print("Cannot create audio converter")
            return
        }

        let frameCapacity: AVAudioFrameCount = 1600

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity)!
            var error: NSError?

            let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            guard status != .error, error == nil, outputBuffer.frameLength > 0 else { return }

            let byteCount = Int(outputBuffer.frameLength) * 2
            let data = Data(bytes: outputBuffer.int16ChannelData![0], count: byteCount)
            let base64 = data.base64EncodedString()

            let msg: [String: Any] = [
                "realtimeInput": [
                    "audio": [
                        "data": base64,
                        "mimeType": "audio/pcm;rate=16000"
                    ]
                ]
            ]

            Task { @MainActor in
                self.sendJSON(msg)
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    func stopAudioInput() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    // MARK: - Audio Output (Server → Speaker)
    private func setupAudioOutput() {
        playerEngine.attach(playerNode)
        playerEngine.connect(playerNode, to: playerEngine.mainMixerNode, format: outputFormat)
        do {
            playerEngine.prepare()
            try playerEngine.start()
            playerNode.play()
        } catch {
            print("Player engine error: \(error)")
        }
    }

    private func stopAudioOutput() {
        playerNode.stop()
        if playerEngine.isRunning {
            playerEngine.stop()
        }
    }

    private func playAudioData(_ data: Data) {
        guard !data.isEmpty else { return }
        let frameCount = AVAudioFrameCount(data.count / 2)
        guard frameCount > 0, let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        data.withUnsafeBytes { rawPtr in
            if let src = rawPtr.baseAddress {
                memcpy(buffer.int16ChannelData![0], src, data.count)
            }
        }

        playerNode.scheduleBuffer(buffer)
        if !isAISpeaking { isAISpeaking = true }
    }

    private func flushAudioPlayback() {
        playerNode.stop()
        playerNode.play()
        isAISpeaking = false
    }

    // MARK: - Video Frames (Camera → Server at ~1 FPS)
    func startVideoStream() {
        videoTimer?.invalidate()
        videoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let handler = self.captureFrameHandler, let jpeg = handler() else { return }
                let base64 = jpeg.base64EncodedString()
                let msg: [String: Any] = [
                    "realtimeInput": [
                        "video": [
                            "data": base64,
                            "mimeType": "image/jpeg"
                        ]
                    ]
                ]
                self.sendJSON(msg)
            }
        }
    }

    func stopVideoStream() {
        videoTimer?.invalidate()
        videoTimer = nil
    }

    // MARK: - WebSocket Send
    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }
        webSocket?.send(.string(text)) { error in
            if let error = error {
                print("WS send error: \(error)")
            }
        }
    }

    // MARK: - WebSocket Receive
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleServerMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleServerMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveMessage()

                case .failure(let error):
                    print("WS receive error: \(error)")
                    if self.errorMessage == nil {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isConnected = false
                    self.onSessionEnd?()
                }
            }
        }
    }

    // MARK: - Handle Server Messages
    private func handleServerMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        // Setup complete
        if json["setupComplete"] != nil {
            print("Setup complete!")
            isConnected = true
            setupAudioOutput()
            startAudioInput()
            return
        }

        // Server content
        if let serverContent = json["serverContent"] as? [String: Any] {
            if let modelTurn = serverContent["modelTurn"] as? [String: Any],
               let parts = modelTurn["parts"] as? [[String: Any]] {
                for part in parts {
                    if let inlineData = part["inlineData"] as? [String: Any],
                       let base64Str = inlineData["data"] as? String,
                       let audioData = Data(base64Encoded: base64Str) {
                        playAudioData(audioData)
                    }
                }
            }

            if let inputTx = serverContent["inputTranscription"] as? [String: Any],
               let t = inputTx["text"] as? String {
                transcript += t
            }

            if let outputTx = serverContent["outputTranscription"] as? [String: Any],
               let t = outputTx["text"] as? String {
                aiTranscript += t
            }

            if let turnComplete = serverContent["turnComplete"] as? Bool, turnComplete {
                isAISpeaking = false
            }

            if let interrupted = serverContent["interrupted"] as? Bool, interrupted {
                flushAudioPlayback()
            }
        }

        // Error from server
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("Server error: \(message)")
            errorMessage = message
        }

        // Go away
        if json["goAway"] != nil {
            errorMessage = "Session ending soon"
        }
    }
}

// MARK: - WebSocket Delegate
private class WSDelegate: NSObject, URLSessionWebSocketDelegate {
    let onOpen: () -> Void
    let onClose: (String?) -> Void

    init(onOpen: @escaping () -> Void, onClose: @escaping (String?) -> Void) {
        self.onOpen = onOpen
        self.onClose = onClose
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        onOpen()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonStr = reason.flatMap { String(data: $0, encoding: .utf8) }
        print("WebSocket closed: \(closeCode) \(reasonStr ?? "")")
        onClose(reasonStr)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("WebSocket task error: \(error)")
            onClose(error.localizedDescription)
        }
    }
}
