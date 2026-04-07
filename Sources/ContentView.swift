import SwiftUI
// import MediaPipeTasksGenAI

class GemmaInferenceManager: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isResponding: Bool = false
    private var personalizedMemoryContext: String = ""
    
    init() { loadMemory() }
    
    func sendMessage(_ text: String) {
        chatHistory.append(ChatMessage(role: .user, content: text))
        personalizedMemoryContext += "\nUser: \(text)"
        isResponding = true
        
        DispatchQueue.global().async {
            let prompt = "\(self.personalizedMemoryContext)\nModel: "
            Thread.sleep(forTimeInterval: 1.5)
            let responseText = "这是基于端侧大模型和你的记忆生成的回复。(云端编译测试版)"
            
            DispatchQueue.main.async {
                self.chatHistory.append(ChatMessage(role: .model, content: responseText))
                self.personalizedMemoryContext += "\nModel: \(responseText)"
                self.saveMemory()
                self.isResponding = false
            }
        }
    }
    
    func clearMemory() {
        personalizedMemoryContext = ""
        chatHistory.removeAll()
        saveMemory()
        chatHistory.append(ChatMessage(role: .system, content: "🧹 个性化记忆已成功清除。"))
    }
    
    private func saveMemory() { UserDefaults.standard.set(personalizedMemoryContext, forKey: "GemmaUserMemory") }
    private func loadMemory() { if let saved = UserDefaults.standard.string(forKey: "GemmaUserMemory") { personalizedMemoryContext = saved } }
}

enum ChatRole { case user, model, system }
struct ChatMessage: Identifiable { let id = UUID(); let role: ChatRole; let content: String }

struct ContentView: View {
    @StateObject private var inferenceManager = GemmaInferenceManager()
    @State private var inputText: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(inferenceManager.chatHistory) { message in
                        HStack {
                            if message.role == .user { Spacer() }
                            Text(message.content)
                                .padding(10)
                                .background(message.role == .user ? Color.blue : (message.role == .model ? Color.green : Color.clear))
                                .foregroundColor(message.role == .system ? .gray : .white)
                                .cornerRadius(10)
                            if message.role == .model || message.role == .system { Spacer() }
                        }.padding(.horizontal).padding(.top, 5)
                    }
                }
                HStack {
                    TextField("输入消息...", text: $inputText).textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        guard !inputText.isEmpty else { return }
                        inferenceManager.sendMessage(inputText)
                        inputText = ""
                    }) { Image(systemName: "paperplane.fill") }.disabled(inferenceManager.isResponding)
                }.padding()
            }
            .navigationTitle("Gemma Edge")
            .navigationBarItems(trailing: Button(action: { inferenceManager.clearMemory() }) {
                Image(systemName: "trash").foregroundColor(.red)
            })
        }
    }
}
