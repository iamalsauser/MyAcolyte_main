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
                // User profile section
                VStack(spacing: 16) {
                    // Profile image
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Student Profile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Medical Student")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Stats row
                    HStack(spacing: 20) {
                        StatItem(value: "23h", label: "Study Time")
                        
                        Divider()
                            .frame(height: 40)
                        
                        StatItem(value: "75%", label: "Progress")
                        
                        Divider()
                            .frame(height: 40)
                        
                        StatItem(value: "12", label: "Documents")
                    }
                    .padding(.vertical, 8)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Appearance Settings
                SettingsSection(title: "Appearance", systemImage: "paintbrush") {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                        .padding(.vertical, 4)
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
                    LabeledSettingRow(label: "Default Sort Order") {
                        Picker("", selection: $sortPreference) {
                            Text("Name (A-Z)").tag(0)
                            Text("Name (Z-A)").tag(1)
                            Text("Newest First").tag(2)
                            Text("Oldest First").tag(3)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    LabeledSettingRow(label: "Auto-Save Interval") {
                        Picker("", selection: $autoSaveInterval) {
                            ForEach(autoSaveOptions, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .labelsHidden()
                    }
                }
                
                // Notifications Settings
                SettingsSection(title: "Notifications", systemImage: "bell") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .padding(.vertical, 4)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    
                    Divider()
                    
                    Toggle("Study Reminders", isOn: .constant(true))
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("New Content Alerts", isOn: .constant(true))
                        .padding(.vertical, 4)
                        .disabled(!notificationsEnabled)
                }
                
                // Account Section
                SettingsSection(title: "Account", systemImage: "person.circle") {
                    NavigationButton(
                        label: "Study Progress",
                        icon: "chart.bar.fill",
                        color: .green
                    ) {
                        // Navigate to Study Progress screen
                    }
                    
                    Divider()
                    
                    NavigationButton(
                        label: "Achievements",
                        icon: "medal",
                        color: .orange
                    ) {
                        // Navigate to Achievements screen
                    }
                    
                    Divider()
                    
                    NavigationButton(
                        label: "Cloud Sync",
                        icon: "cloud",
                        color: .blue,
                        value: "Off"
                    ) {
                        // Navigate to Cloud Sync settings
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
                                    .foregroundColor(.green)
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
                                Text("Notes")
                                    .font(.subheadline)
                                Text("0.2 GB")
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
                        }
                        .padding(.top, 8)
                    }
                    
                    Divider()
                    
                    Button(action: {
                        // Clean cache action here
                    }) {
                        HStack {
                            Text("Clean Cache")
                                .foregroundColor(.green)
                            Spacer()
                            Text("156 MB")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Support Section
                SettingsSection(title: "Support", systemImage: "questionmark.circle") {
                    NavigationButton(
                        label: "Help Center",
                        icon: "lifepreserver",
                        color: .purple
                    ) {
                        // Navigate to help center
                        if let url = URL(string: "https://help.myacolyte.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Divider()
                    
                    NavigationButton(
                        label: "Contact Support",
                        icon: "envelope",
                        color: .blue
                    ) {
                        // Contact Support
                        if let url = URL(string: "mailto:support@myacolyte.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Divider()
                    
                    NavigationButton(
                        label: "Privacy Policy",
                        icon: "lock.shield",
                        color: .gray
                    ) {
                        // Open privacy policy
                        if let url = URL(string: "https://myacolyte.com/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                // Version info
                Text("Version 1.0.0")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
            .padding(.vertical)
        }
        .navigationTitle("Profile")
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

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.green)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

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
                    .foregroundColor(.green)
                    .frame(width: 26, height: 26)
                
                Text(title)
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            content
                .padding(.leading, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LabeledSettingRow<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            content
        }
        .padding(.vertical, 4)
    }
}

struct NavigationButton: View {
    let label: String
    let icon: String
    let color: Color
    var value: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
        }
    }
}
