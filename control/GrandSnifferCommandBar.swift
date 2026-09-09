import AppKit
import SwiftUI

private enum GrandSnifferCommand: String {
    case zoomOut
    case zoomIn
    case resetZoom
    case focusPrevious
    case focusNext
    case resetFocus
    case search
    case showInfo
}

private extension Notification.Name {
    static let grandSnifferCommand = Notification.Name("GrandSnifferCommand")
    static let grandSnifferCommandBarState = Notification.Name("GrandSnifferCommandBarState")
}

private struct GrandSnifferCommandBarState {
    var canZoomOut = false
    var canZoomIn = false
    var canResetZoom = false
    var canFocusPrevious = false
    var canFocusNext = false
    var canResetFocus = false

    init(notification: Notification? = nil) {
        guard let values = notification?.userInfo else {
            return
        }

        canZoomOut = values["canZoomOut"] as? Bool ?? false
        canZoomIn = values["canZoomIn"] as? Bool ?? false
        canResetZoom = values["canResetZoom"] as? Bool ?? false
        canFocusPrevious = values["canFocusPrevious"] as? Bool ?? false
        canFocusNext = values["canFocusNext"] as? Bool ?? false
        canResetFocus = values["canResetFocus"] as? Bool ?? false
    }
}

@available(macOS 11.0, *)
private struct GrandSnifferCommandBarView: View {
    @State private var state = GrandSnifferCommandBarState()
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                commandButton(
                    title: "Zoom out",
                    systemImage: "minus.magnifyingglass",
                    command: .zoomOut,
                    enabled: state.canZoomOut
                )
                commandButton(
                    title: "Zoom in",
                    systemImage: "plus.magnifyingglass",
                    command: .zoomIn,
                    enabled: state.canZoomIn
                )
                commandButton(
                    title: "Reset zoom",
                    systemImage: "arrow.uturn.backward",
                    command: .resetZoom,
                    enabled: state.canResetZoom
                )
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.regularMaterial)
            )

            Divider()
                .frame(height: 20)

            HStack(spacing: 2) {
                commandButton(
                    title: "Previous focus",
                    systemImage: "chevron.up",
                    command: .focusPrevious,
                    enabled: state.canFocusPrevious
                )
                commandButton(
                    title: "Next focus",
                    systemImage: "chevron.down",
                    command: .focusNext,
                    enabled: state.canFocusNext
                )
                commandButton(
                    title: "Reset focus",
                    systemImage: "scope",
                    command: .resetFocus,
                    enabled: state.canResetFocus
                )
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.regularMaterial)
            )

            Divider()
                .frame(height: 20)

            searchField

            Button {
                send(command: .search, userInfo: ["query": searchText])
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Search files")
            .accessibilityLabel("Search files")

            Button {
                searchText = ""
                send(command: .search, userInfo: ["query": ""])
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Clear search")
            .accessibilityLabel("Clear search")
            .disabled(searchText.isEmpty)

            Spacer(minLength: 8)

            commandButton(
                title: "Show info",
                systemImage: "info.circle",
                command: .showInfo
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(
            NotificationCenter.default.publisher(for: .grandSnifferCommandBarState)
        ) { notification in
            state = GrandSnifferCommandBarState(notification: notification)
        }
    }

    @ViewBuilder
    private var searchField: some View {
        if #available(macOS 12.0, *) {
            TextField("Filter files", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 150, idealWidth: 210, maxWidth: 260)
                .onSubmit {
                    send(command: .search, userInfo: ["query": searchText])
                }
        } else {
            TextField("Filter files", text: $searchText, onCommit: {
                send(command: .search, userInfo: ["query": searchText])
            })
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 150, idealWidth: 210, maxWidth: 260)
        }
    }

    private func commandButton(
        title: String,
        systemImage: String,
        command: GrandSnifferCommand,
        enabled: Bool = true
    ) -> some View {
        Button {
            send(command: command)
        } label: {
            Image(systemName: systemImage)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help(title)
        .accessibilityLabel(title)
        .disabled(!enabled)
    }

    private func send(command: GrandSnifferCommand, userInfo: [String: Any] = [:]) {
        var values = userInfo
        values["command"] = command.rawValue
        NotificationCenter.default.post(
            name: .grandSnifferCommand,
            object: nil,
            userInfo: values
        )
    }
}

@objc(GrandSnifferCommandBarFactory)
@available(macOS 11.0, *)
public final class GrandSnifferCommandBarFactory: NSObject {
    @objc public static func makeView() -> NSView {
        let hostingView = NSHostingView(rootView: GrandSnifferCommandBarView())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        return hostingView
    }
}
