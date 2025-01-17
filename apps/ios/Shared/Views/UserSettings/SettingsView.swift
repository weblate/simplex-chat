//
//  SettingsView.swift
//  SimpleX
//
//  Created by Evgeny Poberezkin on 31/01/2022.
//  Copyright © 2022 SimpleX Chat. All rights reserved.
//

import SwiftUI

let simplexTeamURL = URL(string: "simplex:/contact#/?v=1&smp=smp%3A%2F%2FPQUV2eL0t7OStZOoAsPEV2QYWt4-xilbakvGUGOItUo%3D%40smp6.simplex.im%2FK1rslx-m5bpXVIdMZg9NLUZ_8JBm8xTt%23MCowBQYDK2VuAyEALDeVe-sG8mRY22LsXlPgiwTNs9dbiLrNuA7f3ZMAJ2w%3D")!

let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

let appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")  as? String

let DEFAULT_USE_NOTIFICATIONS = "useNotifications"
let DEFAULT_PENDING_CONNECTIONS = "pendingConnections"

private var indent: CGFloat = 36

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var chatModel: ChatModel
    @Binding var showSettings: Bool
    @AppStorage(DEFAULT_USE_NOTIFICATIONS) private var useNotifications = false
    @AppStorage(DEFAULT_PENDING_CONNECTIONS) private var pendingConnections = true
    @State var showNotificationsAlert: Bool = false
    @State var whichNotificationsAlert = NotificationAlert.enable

    var body: some View {
        let user: User = chatModel.currentUser!

        return NavigationView {
            List {
                Section("You") {
                    NavigationLink {
                        UserProfile()
                            .navigationTitle("Your chat profile")
                    } label: {
                        HStack {
                            ProfileImage(imageStr: user.image)
                                .frame(width: 44, height: 44)
                                .padding(.trailing, 6)
                                .padding(.vertical, 6)
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .fontWeight(.bold)
                                    .font(.title2)
                                Text(user.fullName)
                            }
                        }
                        .padding(.leading, -8)
                    }
                    NavigationLink {
                        UserAddress()
                            .navigationTitle("Your chat address")
                    } label: {
                        settingsRow("qrcode") { Text("Your SimpleX contact address") }
                    }
                }
                
                Section("Settings") {
                    settingsRow("link") {
                        Toggle("Show pending connections", isOn: $pendingConnections)
                    }
                    NavigationLink {
                        SMPServers()
                            .navigationTitle("Your SMP servers")
                    } label: {
                        settingsRow("server.rack") { Text("SMP servers") }
                    }
                }

                Section("Help") {
                    NavigationLink {
                        ChatHelp(showSettings: $showSettings)
                            .navigationTitle("Welcome \(user.displayName)!")
                            .frame(maxHeight: .infinity, alignment: .top)
                    } label: {
                        settingsRow("questionmark") { Text("How to use it") }
                    }
                    NavigationLink {
                        SimpleXInfo(onboarding: false)
                            .navigationBarTitle("", displayMode: .inline)
                            .frame(maxHeight: .infinity, alignment: .top)
                    } label: {
                        settingsRow("info") { Text("About SimpleX Chat") }
                    }
                    NavigationLink {
                        MarkdownHelp()
                            .navigationTitle("How to use markdown")
                            .frame(maxHeight: .infinity, alignment: .top)
                    } label: {
                        settingsRow("textformat") { Text("Markdown in messages") }
                    }
                    settingsRow("number") {
                        Button {
                            showSettings = false
                            DispatchQueue.main.async {
                                UIApplication.shared.open(simplexTeamURL)
                            }
                        } label: {
                            Text("Chat with the developers")
                        }
                    }
                    settingsRow("envelope") { Text("[Send us email](mailto:chat@simplex.chat)") }
                }

                Section("Develop") {
                    NavigationLink {
                        TerminalView()
                    } label: {
                        settingsRow("terminal") { Text("Chat console") }
                    }
                    ZStack(alignment: .leading) {
                        Image(colorScheme == .dark ? "github_light" : "github")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Install [SimpleX Chat for terminal](https://github.com/simplex-chat/simplex-chat)")
                            .padding(.leading, indent)
                    }
//                    if let token = chatModel.deviceToken {
//                        HStack {
//                            notificationsIcon()
//                            notificationsToggle(token)
//                        }
//                    }
//                    NavigationLink {
//                        CallViewDebug()
//                            .frame(maxHeight: .infinity, alignment: .top)
//                    } label: {
                        Text("v\(appVersion ?? "?") (\(appBuild ?? "?"))")
//                    }
                }
            }
            .navigationTitle("Your settings")
        }
    }

    private func settingsRow<Content : View>(_ icon: String, content: @escaping () -> Content) -> some View {
        ZStack(alignment: .leading) {
            Image(systemName: icon).frame(maxWidth: 24, maxHeight: 24, alignment: .center)
            content().padding(.leading, indent)
        }
    }

    enum NotificationAlert {
        case enable
        case error(LocalizedStringKey, String)
    }

    private func notificationsIcon() -> some View {
        let icon: String
        let color: Color
        switch (chatModel.tokenStatus) {
        case .new:
            icon = "bolt"
            color = .primary
        case .registered:
            icon = "bolt.fill"
            color = .primary
        case .invalid:
            icon = "bolt.slash"
            color = .primary
        case .confirmed:
            icon = "bolt.fill"
            color = .yellow
        case .active:
            icon = "bolt.fill"
            color = .green
        case .expired:
            icon = "bolt.slash.fill"
            color = .primary
        }
        return Image(systemName: icon)
            .padding(.trailing, 9)
            .foregroundColor(color)
    }

    private func notificationsToggle(_ token:  String) -> some View {
        Toggle("Check messages", isOn: $useNotifications)
            .onChange(of: useNotifications) { enable in
                if enable {
                    showNotificationsAlert = true
                    whichNotificationsAlert = .enable
                } else {
                    Task {
                        do {
                            try await apiDeleteToken(token: token)
                            chatModel.tokenStatus = .new
                        }
                        catch {
                            DispatchQueue.main.async {
                                if let cr = error as? ChatResponse {
                                    let err = String(describing: cr)
                                    logger.error("apiDeleteToken error: \(err)")
                                    showNotificationsAlert = true
                                    whichNotificationsAlert = .error("Error deleting token", err)
                                } else {
                                    logger.error("apiDeleteToken unknown error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $showNotificationsAlert) {
                switch (whichNotificationsAlert) {
                case .enable: return enableNotificationsAlert(token)
                case let .error(title, err): return Alert(title: Text(title), message: Text(err))
                }
            }
    }

    private func enableNotificationsAlert(_ token: String) -> Alert {
        Alert(
            title: Text("Enable notifications? (BETA)"),
            message: Text("The app can receive background notifications every 20 minutes to check the new messages.\n*Please note*: if you confirm, your device token will be sent to SimpleX Chat notifications server."),
            primaryButton: .destructive(Text("Confirm")) {
                Task {
                    do {
                        chatModel.tokenStatus = try await apiRegisterToken(token: token)
                    } catch {
                        DispatchQueue.main.async {
                            useNotifications = false
                            if let cr = error as? ChatResponse {
                                let err = String(describing: cr)
                                logger.error("apiRegisterToken error: \(err)")
                                showNotificationsAlert = true
                                whichNotificationsAlert = .error("Error registering token", err)
                            } else {
                                logger.error("apiRegisterToken unknown error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }, secondaryButton: .cancel() {
                withAnimation() { useNotifications = false }
            }
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let chatModel = ChatModel()
        chatModel.currentUser = User.sampleData
        @State var showSettings = false

        return SettingsView(showSettings: $showSettings)
            .environmentObject(chatModel)
    }
}
