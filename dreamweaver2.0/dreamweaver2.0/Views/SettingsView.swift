import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showVoiceSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                // Audio & Voice Section
                Section {
                    NavigationLink {
                        VoiceSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Voice Settings")
                                    .font(.body)
                                Text("Customize text-to-speech voice and settings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Audio & Voice")
                }
                
                // Story Generation Section
                Section {
                    HStack {
                        Image(systemName: "text.book.closed.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Story Preferences")
                            Text("Coming soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "brain.head.profile.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Settings")
                            Text("Customize AI generation parameters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Story Generation")
                }
                
                // Account Section
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Account Settings")
                            Text("Manage your profile and preferences")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Data & Sync")
                            Text("Manage story sync and backups")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Account")
                }
                
                // About Section
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("About DreamWeaver")
                            Text("Version \(AppConfig.appVersion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Help & Support")
                            Text("Get help and contact support")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 