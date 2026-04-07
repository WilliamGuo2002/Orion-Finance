import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

// MARK: - Chat session summary (for the list)
struct ChatSession: Identifiable {
    let id: String
    let messages: [ChatMessage]
    let timestamp: Date
    var preview: String {
        messages.first?.content ?? L("Empty chat")
    }
}

// MARK: - Chat List View (entry point for the Chat tab)
struct ChatView: View {
    @State private var sessions: [ChatSession] = []
    @State private var isLoading = false
    @State private var activeChatId: String?
    @State private var navigateToChat = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("Orion AI"))
                    .font(AppTheme.serifTitle(22))
                    .foregroundColor(AppTheme.primaryText)
                Spacer()
                Button(action: createNewChat) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundColor(AppTheme.primaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if isLoading && sessions.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if sessions.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.08))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(AppTheme.accent.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppTheme.accent)
                    }

                    VStack(spacing: 8) {
                        Text(L("No conversations yet"))
                            .font(AppTheme.serifHeadline(18))
                            .foregroundColor(AppTheme.primaryText)
                        Text(L("Ask Orion anything about stocks, markets, or investing"))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: createNewChat) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text(L("Start a new chat"))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(AppTheme.accent))
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(.horizontal, 40)
                Spacer()
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(destination: ChatDetailView(
                            chatId: session.id,
                            initialMessages: session.messages,
                            isExistingChat: true
                        )) {
                            ChatSessionRow(session: session)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
                .listStyle(.plain)
                .refreshable { await loadSessions() }
            }
        }
        .background(AppTheme.background)
        .navigationDestination(isPresented: $navigateToChat) {
            if let chatId = activeChatId {
                ChatDetailView(chatId: chatId, initialMessages: [])
            }
        }
        .task {
            await loadSessions()
        }
    }

    private func loadSessions() async {
        isLoading = true
        let raw = await FirebaseController.shared.getChatSessions()
        let loaded = raw.map { item in
            ChatSession(
                id: item.id,
                messages: item.messages.map { ChatMessage(role: $0["role"] ?? "user", content: $0["content"] ?? "") },
                timestamp: item.timestamp
            )
        }
        await MainActor.run {
            sessions = loaded
            isLoading = false
        }
    }

    private func createNewChat() {
        Haptic.tap()
        let newId = String(Int(Date().timeIntervalSince1970 * 1000))
        activeChatId = newId
        navigateToChat = true
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = sessions[index]
            FirebaseController.shared.deleteChatHistory(chatId: session.id)
        }
        sessions.remove(atOffsets: offsets)
    }
}

// MARK: - Chat Session Row
struct ChatSessionRow: View {
    let session: ChatSession

    private var dateString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(session.timestamp) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: session.timestamp)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.fill")
                .foregroundColor(AppTheme.secondaryText)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.preview)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
                Text("\(session.messages.count) \(L("messages"))")
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            Text(dateString)
                .font(AppTheme.caption())
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Detail View (actual conversation)
struct ChatDetailView: View {
    let chatId: String
    let initialMessages: [ChatMessage]
    var isExistingChat: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var userInput = ""
    @State private var isLoading = false
    @State private var navigateToNewChat = false
    @State private var newChatId: String?
    @State private var isTemporary = false

    // Attachments
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var attachedImageData: Data?
    @State private var attachedFileName: String?
    @State private var attachedFileText: String?
    @State private var showFilePicker = false

    // Voice / Video
    @State private var showVoiceChat = false
    @State private var showVideoChat = false

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: msg.role == "user" ? .trailing : .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.horizontal, 16)
                                Text(L("Thinking..."))
                                    .foregroundColor(AppTheme.secondaryText)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Attachment preview
            if attachedImageData != nil || attachedFileName != nil {
                attachmentPreview
            }

            // Input bar
            HStack(spacing: 6) {
                // Photo picker
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.secondaryText)
                }

                // File picker
                Button(action: { showFilePicker = true }) {
                    Image(systemName: "doc")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.secondaryText)
                }

                TextField(L("Ask Orion..."), text: $userInput)
                    .textFieldStyle(.roundedBorder)

                // Voice chat (Gemini Live)
                Button(action: { showVoiceChat = true }) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.secondaryText)
                }

                // Video chat (Gemini Live)
                Button(action: { showVideoChat = true }) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.secondaryText)
                }

                // Send text
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(canSend ? AppTheme.accent : AppTheme.secondaryText)
                }
                .disabled(!canSend || isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider().opacity(0.3)
            }
            .padding(.bottom, 64)
        }
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isTemporary ? L("Temporary Chat") : "Orion")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.barBackground)
                            .shadow(color: AppTheme.primaryText.opacity(0.08), radius: 2, y: 1)
                    )
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if isExistingChat {
                    Button(action: startNewChat) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppTheme.primaryText)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(AppTheme.barBackground)
                                    .shadow(color: AppTheme.primaryText.opacity(0.08), radius: 2, y: 1)
                            )
                    }
                } else {
                    Button(action: { isTemporary.toggle() }) {
                        Image(systemName: isTemporary ? "clock.badge.xmark" : "clock")
                            .foregroundColor(isTemporary ? AppTheme.warning : AppTheme.primaryText)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(AppTheme.barBackground)
                                    .shadow(color: AppTheme.primaryText.opacity(0.08), radius: 2, y: 1)
                            )
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToNewChat) {
            if let id = newChatId {
                ChatDetailView(chatId: id, initialMessages: [], isExistingChat: false)
            }
        }
        .fullScreenCover(isPresented: $showVoiceChat) {
            GeminiVoiceChatView(messages: $messages, isTemporary: isTemporary, chatId: chatId)
        }
        .fullScreenCover(isPresented: $showVideoChat) {
            GeminiVideoChatView(messages: $messages, isTemporary: isTemporary, chatId: chatId)
        }
        .onAppear {
            messages = initialMessages
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data),
                       let jpeg = uiImage.jpegData(compressionQuality: 0.7) {
                        await MainActor.run {
                            attachedImageData = jpeg
                            attachedFileName = nil
                            attachedFileText = nil
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText, .pdf, .json, .xml, .sourceCode, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    // MARK: - Attachment Preview
    @ViewBuilder
    private var attachmentPreview: some View {
        HStack(spacing: 8) {
            if let imgData = attachedImageData, let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .cornerRadius(8)
                    .clipped()
                Text(L("Photo attached"))
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.secondaryText)
            } else if let name = attachedFileName {
                Image(systemName: "doc.fill")
                    .foregroundColor(AppTheme.secondaryText)
                Text(name)
                    .font(AppTheme.caption())
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: clearAttachment) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(AppTheme.subtleFill)
    }

    private var canSend: Bool {
        let hasText = !userInput.trimmingCharacters(in: .whitespaces).isEmpty
        let hasAttachment = attachedImageData != nil || attachedFileText != nil
        return hasText || hasAttachment
    }

    private func clearAttachment() {
        attachedImageData = nil
        attachedFileName = nil
        attachedFileText = nil
        selectedPhoto = nil
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let name = url.lastPathComponent
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            let truncated = String(text.prefix(10000))
            attachedFileName = name
            attachedFileText = truncated
            attachedImageData = nil
        }
    }

    private func startNewChat() {
        let id = String(Int(Date().timeIntervalSince1970 * 1000))
        newChatId = id
        navigateToNewChat = true
    }

    private func sendMessage() {
        let text = userInput.trimmingCharacters(in: .whitespaces)
        guard canSend else { return }
        Haptic.tap()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        let imageData = attachedImageData
        let fileName = attachedFileName
        let fileText = attachedFileText

        var displayText = text
        if let fileName = fileName {
            displayText += displayText.isEmpty ? "[\(fileName)]" : "\n[\(fileName)]"
        }

        let userMsg = ChatMessage(
            role: "user",
            content: displayText,
            imageData: imageData,
            fileName: fileName,
            fileText: fileText
        )
        withAnimation(AppTheme.gentleSpring) {
            messages.append(userMsg)
        }
        userInput = ""
        clearAttachment()
        isLoading = true

        saveToFirebase()

        Task {
            do {
                let hasMedia = imageData != nil || fileText != nil
                let reply: String
                if hasMedia {
                    reply = try await APIService.shared.sendGeminiMultimodal(
                        text: text.isEmpty ? "Describe this." : text,
                        imageData: imageData,
                        fileText: fileText
                    )
                } else {
                    reply = try await APIService.shared.sendGeminiMessage(text: text)
                }
                let aiMsg = ChatMessage(role: "ai", content: reply)
                await MainActor.run {
                    withAnimation(AppTheme.gentleSpring) {
                        messages.append(aiMsg)
                    }
                    isLoading = false
                    Haptic.soft()
                }
                saveToFirebase()
            } catch {
                let errorMsg = ChatMessage(role: "ai", content: "Error: \(error.localizedDescription)")
                await MainActor.run {
                    messages.append(errorMsg)
                    isLoading = false
                    Haptic.error()
                }
            }
        }
    }

    private func saveToFirebase() {
        guard !isTemporary else { return }
        let dicts = messages.map { ["role": $0.role, "content": $0.content] }
        FirebaseController.shared.saveChatMessage(chatId: chatId, messages: dicts)
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            // AI avatar
            if !isUser {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.accent)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                if let imgData = message.imageData, let uiImage = UIImage(data: imgData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 200)
                        .cornerRadius(14)
                }

                if let fileName = message.fileName {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(AppTheme.caption())
                        Text(fileName)
                            .font(AppTheme.caption())
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.subtleFill)
                    .cornerRadius(8)
                }

                if !message.content.isEmpty {
                    Group {
                        if isUser {
                            Text(message.content)
                        } else {
                            MarkdownText(text: message.content)
                        }
                    }
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackground)
                    .foregroundColor(AppTheme.primaryText)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isUser ? Color.clear : AppTheme.border, lineWidth: 0.5)
                    )
                    .shadow(color: isUser ? Color.clear : AppTheme.primaryText.opacity(0.03), radius: 4, y: 2)
                }
            }
            .frame(maxWidth: isUser ? 280 : .infinity, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Gemini Voice Chat (Full Screen)
struct GeminiVoiceChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var live = GeminiLiveService()
    @Binding var messages: [ChatMessage]
    let isTemporary: Bool
    let chatId: String

    @State private var pulsate = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: endSession) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("Orion Voice")
                            .font(.headline)
                            .foregroundColor(.white)
                        if live.isConnected {
                            Text(L("Connected"))
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text(L("Connecting..."))
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    // Spacer to balance layout
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                // Center orb animation
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(live.isAISpeaking ? 1.3 : 1.0)
                        .opacity(live.isAISpeaking ? 0.5 : 0.2)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: live.isAISpeaking)

                    Circle()
                        .stroke(Color.blue.opacity(0.5), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(live.isAISpeaking ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: live.isAISpeaking)

                    // Core orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: live.isAISpeaking ? "waveform" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .symbolEffect(.variableColor.iterative, isActive: live.isAISpeaking)
                }

                Spacer()
                    .frame(height: 30)

                // AI transcript
                if !live.aiTranscript.isEmpty {
                    ScrollView {
                        Text(live.aiTranscript)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: 120)
                }

                // User transcript
                if !live.transcript.isEmpty {
                    Text(live.transcript)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }

                Spacer()

                // Error message
                if let error = live.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 32)
                }

                // End call button
                Button(action: endSession) {
                    Image(systemName: "phone.down.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 70)
                        .background(Circle().fill(Color.red))
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            live.connect(withVideo: false)
        }
        .onDisappear {
            live.disconnect()
        }
    }

    private func endSession() {
        // Save transcripts as messages
        if !live.transcript.isEmpty {
            messages.append(ChatMessage(role: "user", content: "🎤 " + live.transcript))
        }
        if !live.aiTranscript.isEmpty {
            messages.append(ChatMessage(role: "ai", content: live.aiTranscript))
        }
        if !isTemporary && (!live.transcript.isEmpty || !live.aiTranscript.isEmpty) {
            let dicts = messages.map { ["role": $0.role, "content": $0.content] }
            FirebaseController.shared.saveChatMessage(chatId: chatId, messages: dicts)
        }
        live.disconnect()
        dismiss()
    }
}

// MARK: - Gemini Video Chat (Full Screen)
struct GeminiVideoChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var live = GeminiLiveService()
    @Binding var messages: [ChatMessage]
    let isTemporary: Bool
    let chatId: String

    @State private var captureSession = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var isFrontCamera = true
    @State private var videoOutput = AVCaptureVideoDataOutput()
    @State private var latestFrame: Data?

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: captureSession)
                .ignoresSafeArea()

            VStack {
                // Top bar
                HStack {
                    Button(action: endSession) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Orion Video")
                            .font(.headline)
                            .foregroundColor(.white)
                        if live.isConnected {
                            Text(L("Connected"))
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text(L("Connecting..."))
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.5)))

                    Spacer()

                    Button(action: switchCamera) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 60)

                Spacer()

                // AI transcript bubble
                if !live.aiTranscript.isEmpty {
                    ScrollView {
                        Text(live.aiTranscript)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(12)
                    }
                    .frame(maxHeight: 150)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.6)))
                    .padding(.horizontal, 24)
                }

                // User transcript
                if !live.transcript.isEmpty {
                    Text(live.transcript)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.6)))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // Error
                if let error = live.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
                        .padding(.horizontal, 24)
                }

                // Bottom controls
                HStack(spacing: 50) {
                    // Mute toggle placeholder
                    Button(action: switchCamera) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }

                    // End call
                    Button(action: endSession) {
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Circle().fill(Color.red))
                    }

                    // AI speaking indicator
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: live.isAISpeaking ? "waveform" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .symbolEffect(.variableColor.iterative, isActive: live.isAISpeaking)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupCamera()
            live.captureFrameHandler = { [self] in
                return self.latestFrame
            }
            live.connect(withVideo: true)
            // Start sending video frames once connected
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                live.startVideoStream()
            }
        }
        .onDisappear {
            live.stopVideoStream()
            live.disconnect()
            captureSession.stopRunning()
        }
    }

    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .medium

        let position: AVCaptureDevice.Position = isFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureSession.commitConfiguration()
            return
        }

        captureSession.inputs.forEach { captureSession.removeInput($0) }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        // Video data output for grabbing frames
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        let delegate = VideoFrameDelegate { [self] jpeg in
            self.latestFrame = jpeg
        }
        output.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "video.frame"))
        // Keep delegate alive
        objc_setAssociatedObject(output, "frameDelegate", delegate, .OBJC_ASSOCIATION_RETAIN)

        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }

        captureSession.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }

    private func switchCamera() {
        isFrontCamera.toggle()
        setupCamera()
    }

    private func endSession() {
        // Save transcripts
        if !live.transcript.isEmpty {
            messages.append(ChatMessage(role: "user", content: "📹 " + live.transcript))
        }
        if !live.aiTranscript.isEmpty {
            messages.append(ChatMessage(role: "ai", content: live.aiTranscript))
        }
        if !isTemporary && (!live.transcript.isEmpty || !live.aiTranscript.isEmpty) {
            let dicts = messages.map { ["role": $0.role, "content": $0.content] }
            FirebaseController.shared.saveChatMessage(chatId: chatId, messages: dicts)
        }
        live.stopVideoStream()
        live.disconnect()
        captureSession.stopRunning()
        dismiss()
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Video Frame Delegate (grabs JPEG from camera)
class VideoFrameDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let onFrame: (Data?) -> Void
    private var lastCapture = Date.distantPast

    init(onFrame: @escaping (Data?) -> Void) {
        self.onFrame = onFrame
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle to ~2 FPS for frame storage (server only takes 1 FPS)
        let now = Date()
        guard now.timeIntervalSince(lastCapture) >= 0.5 else { return }
        lastCapture = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)

        // Resize to 768x768 max, JPEG compress
        let maxDim: CGFloat = 768
        let scale = min(maxDim / uiImage.size.width, maxDim / uiImage.size.height, 1.0)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        let jpeg = resized?.jpegData(compressionQuality: 0.5)
        onFrame(jpeg)
    }
}
