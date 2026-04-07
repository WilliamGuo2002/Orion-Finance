import SwiftUI
import WebKit

struct NewsDetailView: View {
    let url: String
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        ZStack {
            WebViewRepresentable(
                urlString: url,
                isLoading: $isLoading,
                loadError: $loadError
            )
            .ignoresSafeArea(edges: .bottom)

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(L("Loading article..."))
                        .font(AppTheme.caption(13))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background.opacity(0.8))
                .transition(.opacity)
            }

            if let error = loadError {
                ErrorStateView(
                    message: error,
                    retryAction: { loadError = nil; isLoading = true }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let linkURL = URL(string: url) {
                    ShareLink(item: linkURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            withAnimation(.easeOut(duration: 0.3)) {
                parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }
    }
}
