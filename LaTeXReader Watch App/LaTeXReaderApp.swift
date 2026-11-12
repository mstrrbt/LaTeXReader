//
//  LaTeXReaderApp.swift
//  LaTeXReader Watch App
//
//  Created by Alexander on 11/10/26.
//

import SwiftUI
import WatchKit

@main
struct PDFReaderApp: App {
    var body: some Scene {
        WindowGroup { DocumentList() }
    }
}

struct DocumentList: View {
    let urls: [URL] = findPDFs()

    var body: some View {
        NavigationStack {
            List {
                if urls.isEmpty {
                    Text("PDF не найдены")
                        .foregroundStyle(.red)
                }
                ForEach(urls, id: \.self) { url in
                    NavigationLink(url.deletingPathExtension().lastPathComponent) {
                        PDFScrollView(url: url)
                    }
                }
            }
        }
    }
}

func findPDFs() -> [URL] {
    let root = Bundle.main.bundleURL
    var result: [URL] = []
    if let en = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
        for case let url as URL in en {
            if url.pathExtension.lowercased() == "pdf" {
                result.append(url)
            }
        }
    }
    return result.sorted { $0.lastPathComponent < $1.lastPathComponent }
}

struct PDFScrollView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var pages: [Int] = []
    @State private var zoom: Double = 1.0

    private var doc: CGPDFDocument? { CGPDFDocument(url as CFURL) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                backButton

                ForEach(pages, id: \.self) { n in
                    PageView(doc: doc, number: n, zoom: zoom)
                }

                backButton   // та же кнопка в конце документа
            }
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .navigationBar)
        .focusable()
        .digitalCrownRotation($zoom, from: 1.0, through: 3.0, by: 0.1,
                              sensitivity: .low, isContinuous: false)
        .onAppear {
            if let d = doc { pages = Array(1...max(d.numberOfPages, 1)) }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Label("Назад", systemImage: "chevron.left")
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 24)   // чтобы не прятаться под временем
        .padding(.bottom, 8)
    }
}

struct PageView: View {
    let doc: CGPDFDocument?
    let number: Int
    let zoom: Double
    @State private var image: CGImage?

    private let scale = WKInterfaceDevice.current().screenScale

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: scale)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task(id: zoom) {
            guard let page = doc?.page(at: number) else { return }
            let w = WKInterfaceDevice.current().screenBounds.width * zoom
            image = renderPage(page, width: w, scale: scale)
        }
    }
}
