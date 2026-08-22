import SwiftUI

struct MessagesView: View {
    @Environment(AppModel.self) private var model
    @State private var pendingDeleteID: String?

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            Group {
                if !model.session.isSignedIn {
                    EmptyStateView(
                        title: "Сообщения",
                        text: "Войдите, чтобы писать продавцам с карточки авто.",
                        illustration: .messages,
                        actionTitle: "Войти",
                        action: {
                            if RemoteChatStore.isLive {
                                model.selectedTab = .profile
                            } else {
                                model.signInDemo()
                            }
                        }
                    )
                } else {
                    inbox
                }
            }
            .paperCanvas()
            .navigationTitle("Сообщения")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { id in
                ChatThreadView(threadID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if model.unreadCount > 0 {
                        Button("Прочитать") { model.markAllRead() }
                            .fontWeight(.semibold)
                    } else {
                        Button("Каталог") { model.selectedTab = .search }
                            .fontWeight(.semibold)
                    }
                }
            }
            .confirmationDialog(
                "Удалить переписку?",
                isPresented: Binding(
                    get: { pendingDeleteID != nil },
                    set: { if !$0 { pendingDeleteID = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    if let id = pendingDeleteID { model.deleteThread(id) }
                    pendingDeleteID = nil
                }
                Button("Отмена", role: .cancel) { pendingDeleteID = nil }
            }
        }
    }

    private var inbox: some View {
        VStack(spacing: 0) {
            lineTicket
            if !model.chats.isEmpty {
                tabPills
            }
            threadList
        }
    }

    private var lineTicket: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("LINE")
                .font(.caption.monospaced().weight(.bold))
                .tracking(1.6)
            Text(model.inboxHeadline)
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(AutoraTheme.canvas)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .padding(.horizontal, AutoraTheme.pageGutter)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(model.inboxHeadline)
    }

    private var tabPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxTab.allCases) { item in
                    let count = InboxDesk.listings(
                        model.chats,
                        tab: item,
                        deferredIDs: model.deferredIDs
                    ).count
                    Button {
                        model.inboxTab = item
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text("\(count)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(model.inboxTab == item ? AutoraTheme.canvas.opacity(0.7) : AutoraTheme.muted)
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .foregroundStyle(model.inboxTab == item ? AutoraTheme.canvas : AutoraTheme.ink)
                        .background(
                            model.inboxTab == item ? AutoraTheme.ink : AutoraTheme.surface,
                            in: RoundedRectangle(cornerRadius: AutoraTheme.chipRadius, style: .continuous)
                        )
                    }
                    .buttonStyle(PressableInkStyle())
                    .accessibilityLabel("\(item.title), \(count)")
                    .accessibilityAddTraits(model.inboxTab == item ? .isSelected : [])
                }
            }
            .padding(.horizontal, AutoraTheme.pageGutter)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private var threadList: some View {
        let items = InboxDesk.listings(
            model.chats,
            tab: model.inboxTab,
            deferredIDs: model.deferredIDs
        )
        if model.chats.isEmpty {
            InboxEmpty(
                title: "Нет переписок",
                text: "Напишите продавцу с карточки объявления — ответ придёт сюда.",
                actionTitle: "Открыть каталог",
                action: { model.selectedTab = .search }
            )
        } else if items.isEmpty {
            InboxEmpty(
                title: "В этом разделе пусто",
                text: "Переключите фильтр или напишите с карточки авто.",
                actionTitle: "Показать все",
                action: { model.inboxTab = .all }
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items) { thread in
                        NavigationLink(value: thread.id) {
                            InboxThreadRow(
                                thread: thread,
                                photoURL: model.listing(id: thread.listingId)?.photoURLs.first,
                                now: model.now()
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Удалить", role: .destructive) {
                                pendingDeleteID = thread.id
                            }
                        }
                    }
                }
                .padding(.horizontal, AutoraTheme.pageGutter)
                .padding(.bottom, 28)
            }
        }
    }
}

private struct InboxEmpty: View {
    var title: String
    var text: String
    var actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image("EmptyMessages")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                .accessibilityHidden(true)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(AutoraTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, action: action)
                .font(.body.weight(.bold))
                .foregroundStyle(AutoraTheme.canvas)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                .buttonStyle(PressableInkStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

private struct InboxThreadRow: View {
    let thread: ChatThread
    var photoURL: String?
    var now: TimeInterval

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let photoURL {
                    AutoraRemotePhoto(urlString: photoURL, height: 56, accessibilityText: nil)
                } else {
                    AutoraTheme.surface
                        .overlay {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(AutoraTheme.muted)
                        }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(thread.peerName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    if InboxDesk.lastActivity(thread) > 0 {
                        Text(InboxDesk.timeLabel(at: InboxDesk.lastActivity(thread), now: now))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AutoraTheme.muted)
                    }
                }
                Text(thread.listingTitle)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AutoraTheme.muted)
                    .lineLimit(1)
                Text(InboxDesk.preview(thread))
                    .font(.subheadline)
                    .foregroundStyle(AutoraTheme.ink.opacity(0.85))
                    .lineLimit(2)
            }
            if thread.unread > 0 {
                Text("\(thread.unread)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AutoraTheme.ink, in: Capsule())
                    .foregroundStyle(AutoraTheme.canvas)
                    .accessibilityLabel("\(thread.unread) непрочитанных")
            }
        }
        .padding(12)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
    }
}

struct ChatThreadView: View {
    @Environment(AppModel.self) private var model
    let threadID: String
    @State private var draft = ""
    @State private var showListing = false

    var thread: ChatThread? { model.chats.first { $0.id == threadID } }

    var body: some View {
        VStack(spacing: 0) {
            if let thread {
                listingHeader(thread)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if (thread?.messages ?? []).isEmpty {
                            Text(RemoteChatStore.isLive ? "Пока пусто. Напишите — сообщение уйдёт на сайт." : InboxDesk.waitingForSeller)
                                .font(.footnote)
                                .foregroundStyle(AutoraTheme.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                        }
                        ForEach(thread?.messages ?? []) { message in
                            bubble(message)
                                .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onAppear {
                    scrollToLast(proxy)
                }
                .onChange(of: thread?.messages.count ?? 0) { _, _ in
                    scrollToLast(proxy)
                }
            }
            composer
        }
        .paperCanvas()
        .navigationTitle(thread?.peerName ?? "Чат")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            draft = model.chatDraft(for: threadID)
            model.markThreadRead(threadID)
        }
        .task {
            await model.refreshRemoteThread(threadID)
        }
        .onChange(of: draft) { _, value in
            model.setChatDraft(value, for: threadID)
        }
        .sheet(isPresented: $showListing) {
            if let listing = model.listing(id: thread?.listingId ?? "") {
                NavigationStack {
                    ListingDetailView(listing: listing)
                }
            }
        }
    }

    private func listingHeader(_ thread: ChatThread) -> some View {
        let listing = model.listing(id: thread.listingId)
        return Button {
            showListing = true
        } label: {
            HStack(spacing: 12) {
                if let url = listing?.photoURLs.first {
                    AutoraRemotePhoto(urlString: url, height: 44, accessibilityText: nil)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.listingTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                        .lineLimit(1)
                    Text("Открыть объявление")
                        .font(.caption)
                        .foregroundStyle(AutoraTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AutoraTheme.muted)
            }
            .padding(.horizontal, AutoraTheme.pageGutter)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(listing == nil)
        .accessibilityIdentifier("autora.chat.listing")
        .overlay(alignment: .bottom) {
            Rectangle().fill(AutoraTheme.hairline).frame(height: 1)
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.fromMe { Spacer(minLength: 48) }
            VStack(alignment: message.fromMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        message.fromMe ? AutoraTheme.ink : AutoraTheme.surface,
                        in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                    )
                    .foregroundStyle(message.fromMe ? AutoraTheme.canvas : AutoraTheme.ink)
                Text(InboxDesk.timeLabel(at: message.at, now: model.now()))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(AutoraTheme.muted)
            }
            if !message.fromMe { Spacer(minLength: 48) }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if let listingID = thread?.listingId, let offer = model.deferredOffer(for: listingID) {
                Button(offer.label) {
                    draft = offer.text
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(AutoraTheme.ink)
                .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                .accessibilityIdentifier("autora.chat.offer")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChatDraft.quickReplies, id: \.self) { line in
                        Button(line) { draft = line }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .foregroundStyle(AutoraTheme.ink)
                            .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .buttonStyle(PressableInkStyle())
                    }
                }
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Сообщение", text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(12)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                    .accessibilityIdentifier(AutoraID.chatField)
                Button("Отправить") {
                    guard let text = ChatDraft.normalized(draft) else { return }
                    model.sendMessage(threadID: threadID, text: text)
                    draft = ""
                    model.setChatDraft("", for: threadID)
                }
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 44, minHeight: 44)
                .padding(.horizontal, 12)
                .foregroundStyle(AutoraTheme.canvas)
                .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                .buttonStyle(PressableInkStyle())
                .accessibilityIdentifier(AutoraID.chatSend)
            }
        }
        .padding(.horizontal, AutoraTheme.pageGutter)
        .padding(.vertical, 10)
        .background(AutoraTheme.canvas)
    }

    private func scrollToLast(_ proxy: ScrollViewProxy) {
        guard let last = thread?.messages.last else { return }
        proxy.scrollTo(last.id, anchor: .bottom)
    }
}
