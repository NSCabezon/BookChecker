import SwiftUI
import SwiftData

enum ScanMode: String, CaseIterable, Identifiable {
    case barcode
    case ocr

    var id: String { rawValue }
    var label: String {
        switch self {
        case .barcode: return "Código"
        case .ocr: return "OCR"
        }
    }
}

struct ScannerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.metadataResolver) private var resolver

    @State private var scanMode: ScanMode = .barcode
    @State private var state: ScannerState = .ready
    @State private var lastRawPayload: String?
    @State private var torchOn = false
    @State private var showManualEntry = false
    @State private var draftBeingEdited: BookDraft?
    @State private var programmaticModeFlip = false

    var body: some View {
        ZStack {
            scannerLayer

            VStack {
                if scanMode == .barcode, let payload = lastRawPayload, case .ready = state {
                    DetectedPayloadBadge(payload: payload, accepted: false)
                        .padding(.top, 8)
                }

                Spacer()

                TorchButton(isOn: $torchOn)
                    .padding(.bottom, 12)

                bottomPanel

                Picker("Modo", selection: $scanMode) {
                    ForEach(ScanMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .animation(.snappy, value: state)
            .animation(.snappy, value: lastRawPayload)
            .animation(.snappy, value: scanMode)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualISBNEntryView { isbn in
                Task { await startLookup(isbn: isbn, ean5: nil) }
            }
        }
        .sheet(item: $draftBeingEdited) { _ in
            EditDraftSheet(
                draft: Binding(
                    get: { draftBeingEdited ?? BookDraft() },
                    set: { draftBeingEdited = $0 }
                ),
                onSave: {
                    if let edited = draftBeingEdited {
                        state = .previewing(edited)
                    }
                    draftBeingEdited = nil
                },
                onCancel: { draftBeingEdited = nil }
            )
        }
        .onDisappear { torchOn = false }
        .onChange(of: scanMode) { _, _ in
            if programmaticModeFlip {
                programmaticModeFlip = false
                return
            }
            cancelDraft()
        }
    }

    @ViewBuilder
    private var scannerLayer: some View {
        if !ISBNScanner.isAvailable {
            UnsupportedScannerView()
        } else {
            ISBNScanner(
                torchOn: $torchOn,
                onScan: { isbn, ean5 in
                    guard scanMode == .barcode, state.isReady else { return }
                    Task { await startLookup(isbn: isbn, ean5: ean5) }
                },
                onRawDetect: { payload in
                    guard scanMode == .barcode else { return }
                    lastRawPayload = payload
                },
                onTextTap: { text in
                    guard scanMode == .ocr else { return }
                    handleOCRTap(text)
                }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        switch state {
        case .ready:
            switch scanMode {
            case .barcode:
                ScanHintView(text: "Apunta a un ISBN", actionLabel: "Manual") {
                    showManualEntry = true
                }
                .padding()
            case .ocr:
                OCRPanel(
                    pendingISBN: nil,
                    title: nil,
                    author: nil,
                    onClearTitle: {},
                    onClearAuthor: {},
                    onPrimaryAction: {},
                    onReset: {}
                )
                .opacity(0.6)
                .padding()
            }

        case .lookingUp(let isbn, _):
            LookupSpinner(message: "Buscando ISBN \(isbn)…")
                .padding()

        case .searchingByText(_, _, let title, _):
            LookupSpinner(message: "Buscando: \(title)…")
                .padding()

        case .previewing(let draft):
            PreviewCard(
                draft: draft,
                onConfirm: { confirm(draft) },
                onEdit: { draftBeingEdited = draft },
                onCancel: { cancelDraft() }
            )
            .padding()

        case .editing:
            EmptyView() // sheet handles it

        case .notFound(let isbn, let ean5):
            NotFoundCard(
                isbn: isbn,
                onScanCover: { switchToOCRWithPending(isbn: isbn, ean5: ean5) },
                onCancel: { cancelDraft() }
            )
            .padding()

        case .awaitingOCR(let pendingISBN, _, let title, let authors):
            OCRPanel(
                pendingISBN: pendingISBN,
                title: title,
                author: authors.first,
                onClearTitle: { mutateOCRState { $0.title = nil } },
                onClearAuthor: { mutateOCRState { $0.authors = [] } },
                onPrimaryAction: { performOCRPrimaryAction() },
                onReset: { resetOCRDraft() }
            )
            .padding()

        case .lookupFailed(let isbn, let ean5, let message):
            LookupFailedCard(
                message: message,
                onRetry: { Task { await startLookup(isbn: isbn, ean5: ean5) } },
                onCancel: { cancelDraft() }
            )
            .padding()

        case .deciding(let book):
            DecisionOverlay(book: book) { decision in
                book.decision = decision
                book.updatedAt = .now
                try? context.save()
                state = .ready
                lastRawPayload = nil
            }
            .padding()
        }
    }

    // MARK: - Flow handlers

    private func startLookup(isbn: String, ean5: String?) async {
        state = .lookingUp(isbn: isbn, ean5: ean5)
        let metadata = await resolver.fetch(isbn: isbn)
        if let metadata, metadata.isUsable {
            print("Lookup found via \(metadata.source) for \(isbn)")
            state = .previewing(BookDraft.from(metadata: metadata, isbn: isbn, ean5: ean5))
        } else {
            print("Lookup not found for \(isbn)")
            state = .notFound(isbn: isbn, ean5: ean5)
        }
    }

    private func handleOCRTap(_ text: String) {
        switch state {
        case .ready:
            // Treat first OCR tap as the start of a no-ISBN OCR session.
            state = .awaitingOCR(pendingISBN: nil, pendingEAN5: nil, title: text, authors: [])
        case .awaitingOCR(let pendingISBN, let pendingEAN5, let title, let authors):
            if title == nil {
                state = .awaitingOCR(pendingISBN: pendingISBN, pendingEAN5: pendingEAN5, title: text, authors: authors)
            } else if authors.isEmpty {
                state = .awaitingOCR(pendingISBN: pendingISBN, pendingEAN5: pendingEAN5, title: title, authors: [text])
            } else {
                // Cycle: replace title; clear author.
                state = .awaitingOCR(pendingISBN: pendingISBN, pendingEAN5: pendingEAN5, title: text, authors: [])
            }
        default:
            break
        }
    }

    private func performOCRPrimaryAction() {
        guard case .awaitingOCR(let pendingISBN, let pendingEAN5, let title, let authors) = state,
              let title, !title.isEmpty else { return }

        if pendingISBN != nil {
            Task { await startTextSearch(title: title, author: authors.first, pendingISBN: pendingISBN, pendingEAN5: pendingEAN5) }
        } else {
            state = .previewing(BookDraft(
                isbn: nil,
                ean5: nil,
                title: title,
                authors: authors,
                source: "manual"
            ))
        }
    }

    private func startTextSearch(title: String, author: String?, pendingISBN: String?, pendingEAN5: String?) async {
        state = .searchingByText(pendingISBN: pendingISBN, pendingEAN5: pendingEAN5, title: title, authors: author.map { [$0] } ?? [])
        let metadata = await resolver.search(title: title, author: author)
        if let metadata, metadata.isUsable {
            print("Title-author search found via \(metadata.source)")
            var draft = BookDraft.from(metadata: metadata, isbn: pendingISBN, ean5: pendingEAN5)
            // Preserve the originally captured title/author if metadata is sparse.
            if draft.title?.isEmpty != false { draft.title = title }
            if draft.authors.isEmpty, let author { draft.authors = [author] }
            state = .previewing(draft)
        } else {
            print("Title-author search no match — using raw OCR capture")
            state = .previewing(BookDraft(
                isbn: pendingISBN,
                ean5: pendingEAN5,
                title: title,
                authors: author.map { [$0] } ?? [],
                source: "manual"
            ))
        }
    }

    private func confirm(_ draft: BookDraft) {
        let book = draft.toBook()
        context.insert(book)
        try? context.save()
        state = .deciding(book)
    }

    private func cancelDraft() {
        state = .ready
        lastRawPayload = nil
    }

    private func switchToOCRWithPending(isbn: String, ean5: String?) {
        state = .awaitingOCR(pendingISBN: isbn, pendingEAN5: ean5, title: nil, authors: [])
        programmaticModeFlip = true
        scanMode = .ocr
    }

    private func resetOCRDraft() {
        if case .awaitingOCR(let pendingISBN, let pendingEAN5, _, _) = state {
            state = .awaitingOCR(pendingISBN: pendingISBN, pendingEAN5: pendingEAN5, title: nil, authors: [])
        } else {
            cancelDraft()
        }
    }

    private func mutateOCRState(_ block: (inout OCRDraft) -> Void) {
        guard case .awaitingOCR(let pendingISBN, let pendingEAN5, let title, let authors) = state else { return }
        var draft = OCRDraft(title: title, authors: authors)
        block(&draft)
        state = .awaitingOCR(pendingISBN: pendingISBN, pendingEAN5: pendingEAN5, title: draft.title, authors: draft.authors)
    }
}

private struct OCRDraft {
    var title: String?
    var authors: [String]
}

extension BookDraft: Identifiable {
    var id: String {
        (isbn ?? "") + "|" + (ean5 ?? "") + "|" + (title ?? "") + "|" + authors.joined(separator: ",")
    }
}

#Preview {
    ScannerView()
        .modelContainer(PreviewSamples.inMemoryContainer())
}
