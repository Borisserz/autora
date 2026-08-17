import SwiftUI

struct MessagesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if !model.session.isSignedIn {
                    EmptyStateView(
                        title: "Сообщения",
                        text: "Войдите, чтобы писать продавцам.",
                        illustration: .messages,
                        actionTitle: "Войти",
                        action: { model.signInDemo() }
                    )
                } else if model.chats.isEmpty {
                    EmptyStateView(
                        title: "Нет переписок",
                        text: "Напишите продавцу с карточки объявления.",
                        illustration: .messages,
                        actionTitle: nil
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(model.chats) { thread in
                                NavigationLink(value: thread.id) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(thread.peerName)
                                                .font(.body.weight(.semibold))
                                            Spacer()
                                            if thread.unread > 0 {
                                                Text("\(thread.unread)")
                                                    .font(.caption.bold())
                                                    .padding(6)
                                                    .background(AutoraTheme.ink, in: Circle())
                                                    .foregroundStyle(AutoraTheme.canvas)
                                            }
                                        }
                                        Text(thread.listingTitle)
                                            .font(.subheadline)
                                            .foregroundStyle(AutoraTheme.muted)
                                        if let last = thread.messages.last {
                                            Text(last.text)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.vertical, 14)
                                    .foregroundStyle(AutoraTheme.ink)
                                }
                                Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .paperCanvas()
            .navigationTitle("Сообщения")
            .navigationDestination(for: String.self) { id in
                ChatThreadView(threadID: id)
            }
        }
    }
}

struct ChatThreadView: View {
    @Environment(AppModel.self) private var model
    let threadID: String
    @State private var draft = ""

    var thread: ChatThread? { model.chats.first { $0.id == threadID } }

    var body: some View {
        VStack(spacing: 0) {
            if let thread {
                Button {
                    if let url = URL(string: "autora://listing/\(thread.listingId)") {
                        model.handleDeepLink(url)
                    }
                } label: {
                    Text(thread.listingTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .accessibilityIdentifier("autora.chat.listing")
                Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(thread?.messages ?? []) { message in
                        HStack {
                            if message.fromMe { Spacer() }
                            Text(message.text)
                                .padding(12)
                                .background(
                                    message.fromMe ? AutoraTheme.ink : AutoraTheme.surface,
                                    in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                                )
                                .foregroundStyle(message.fromMe ? AutoraTheme.canvas : AutoraTheme.ink)
                            if !message.fromMe { Spacer() }
                        }
                    }
                }
                .padding(16)
            }
            HStack {
                TextField("Сообщение", text: $draft)
                    .padding(12)
                    .overlay {
                        RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                            .stroke(AutoraTheme.hairline, lineWidth: 1)
                    }
                    .accessibilityIdentifier(AutoraID.chatField)
                Button("Отправить") {
                    guard let text = ChatDraft.normalized(draft) else { return }
                    model.sendMessage(threadID: threadID, text: text)
                    draft = ""
                }
                .fontWeight(.semibold)
                .accessibilityIdentifier(AutoraID.chatSend)
            }
            .padding()
        }
        .paperCanvas()
        .navigationTitle(thread?.peerName ?? "Чат")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.markThreadRead(threadID) }
    }
}
