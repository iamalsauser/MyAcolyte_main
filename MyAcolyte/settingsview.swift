import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var viewModel: FileSystemViewModel
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("sortPreference") private var sortPreference = 0
    @AppStorage("defaultViewMode") private var defaultViewMode = 0
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoSaveInterval") private var autoSaveInterval = 2
    @State private var isShowingResetConfirmation = false
    @State private var showingNotificationPermissionAlert = false
    
    private let autoSaveOptions = [1, 2, 5, 10, 15]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Information Section
                VStack(alignment: .center, spacing: 12) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    
                    Text("MyAcolyte")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                
                // Appearance Settings
                SettingsSection(title: "Appearance", systemImage: "paintbrush") {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .onChange(of: darkModeEnabled) { _, _ in
                            // This would need to be connected to a theme manager in a real app
                        }
                    
                    Divider()
                    
                    Picker("Default View Mode", selection: $defaultViewMode) {
                        Text("Grid View").tag(0)
                        Text("List View").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: defaultViewMode) { _, newValue in
                        viewModel.viewMode = newValue == 0 ? .grid : .list
                    }
                }
                
                // File Management Settings
                SettingsSection(title: "File Management", systemImage: "folder") {
                    Picker("Default Sort Order", selection: $sortPreference) {
                        Text("Name (A-Z)").tag(0)
                        Text("Name (Z-A)").tag(1)
                        Text("Newest First").tag(2)
                        Text("Oldest First").tag(3)
                        Text("Recently Modified").tag(4)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: sortPreference) { _, newValue in
                        switch newValue {
                        case 0: viewModel.changeSortOrder(.nameAscending)
                        case 1: viewModel.changeSortOrder(.nameDescending)
                        case 2: viewModel.changeSortOrder(.dateCreatedNewest)
                        case 3: viewModel.changeSortOrder(.dateCreatedOldest)
                        case 4: viewModel.changeSortOrder(.dateModifiedNewest)
                        default: viewModel.changeSortOrder(.nameAscending)
                        }
                    }
                    
                    Divider()
                    
                    Picker("Auto-Save Interval (minutes)", selection: $autoSaveInterval) {
                        ForEach(0..<autoSaveOptions.count, id: \.self) { index in
                            Text("\(autoSaveOptions[index]) min").tag(autoSaveOptions[index])
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Notifications Settings
                SettingsSection(title: "Notifications", systemImage: "bell") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    
                    Divider()
                    
                    Toggle("File Import Notifications", isOn: .constant(true))
                        .disabled(!notificationsEnabled)
                    
                    Toggle("File Edit Notifications", isOn: .constant(true))
                        .disabled(!notificationsEnabled)
                }
                
                // Account Section (Placeholder for future functionality)
                SettingsSection(title: "Account", systemImage: "person.circle") {
                    Button(action: {
                        // Sign In Action (Placeholder)
                    }) {
                        HStack {
                            Text("Sign In")
                            Spacer()
                            Image(systemName: "arrow.right.circle")
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        // Sync Action (Placeholder)
                    }) {
                        HStack {
                            Text("Cloud Sync")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Off")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Storage Section
                SettingsSection(title: "Storage", systemImage: "internaldrive") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Storage Used")
                            Spacer()
                            Text("3.2 GB of 10 GB")
                                .foregroundColor(.secondary)
                        }
                        
                        // Storage progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 8)
                                    .opacity(0.3)
                                    .foregroundColor(.gray)
                                
                                Rectangle()
                                    .frame(width: geometry.size.width * 0.32, height: 8)
                                    .foregroundColor(.blue)
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 8)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Documents")
                                    .font(.subheadline)
                                Text("1.8 GB")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Whiteboards")
                                    .font(.subheadline)
                                Text("1.2 GB")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Notes")
                                    .font(.subheadline)
                                Text("0.2 GB")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    Button(action: {
                        // Clean cache action here
                    }) {
                        HStack {
                            Text("Clean Cache")
                                .foregroundColor(.blue)
                            Spacer()
                            Text("156 MB")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Support Section
                SettingsSection(title: "Support", systemImage: "questionmark.circle") {
                    Button(action: {
                        // Help Center
                        if let url = URL(string: "https://help.myacolyte.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Help Center")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        // Contact Support
                        if let url = URL(string: "mailto:support@myacolyte.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        // Privacy Policy
                        if let url = URL(string: "https://myacolyte.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Reset Section
                SettingsSection(title: "Reset", systemImage: "arrow.counterclockwise") {
                    Button(action: {
                        isShowingResetConfirmation = true
                    }) {
                        HStack {
                            Text("Reset All Settings")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    
                    Divider()
                    
                    Button(action: {
                        isShowingResetConfirmation = true
                    }) {
                        HStack {
                            Text("Clear All Data")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                Text("© 2025 MyAcolyte. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .navigationTitle("Settings")
        .alert("Reset Confirmation", isPresented: $isShowingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset action here
            }
        } message: {
            Text("Are you sure you want to reset? This action cannot be undone.")
        }
        .alert("Notification Permissions", isPresented: $showingNotificationPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable notifications in Settings to receive alerts.")
        }
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    showingNotificationPermissionAlert = true
                }
            } else if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("❌ Notification permission error: \(error.localizedDescription)")
                    } else {
                        print("✅ Notification permission granted: \(granted)")
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 26, height: 26)
                
                Text(title)
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            content
                .padding(.leading, 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
