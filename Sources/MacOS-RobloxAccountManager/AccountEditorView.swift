import RobloxAccountManagerCore
import SwiftUI

struct AccountEditorView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var record: AccountRecord
    @State private var cookie: String
    @State private var password: String

    init(original: AccountRecord?, secret: AccountSecret) {
        _record = State(initialValue: original ?? AccountRecord(username: ""))
        _cookie = State(initialValue: secret.robloxSecurityCookie)
        _password = State(initialValue: secret.password ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(record.username.isEmpty ? "Add Account" : "Edit Account")
                .font(.title.bold())

            Form {
                TextField("Username", text: $record.username)
                TextField("Alias", text: $record.alias)
                TextField("Group", text: $record.group)
                TextField("User ID", value: $record.userID, format: .number)
                TextField("Saved Place ID", text: $record.savedPlaceID)
                TextField("Saved Job ID / VIP code", text: $record.savedJobID)
                SecureField(".ROBLOSECURITY cookie", text: $cookie)
                if store.settings.savePasswords {
                    SecureField("Optional password", text: $password)
                }
                TextField("Description", text: $record.description, axis: .vertical)
                    .lineLimit(3...6)
            }

            Text("Secrets are stored in the macOS Keychain. Export and backup actions do not include cookies or passwords.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let secret = AccountSecret(
                        robloxSecurityCookie: cookie,
                        password: store.settings.savePasswords ? password : nil
                    )
                    store.saveAccount(record: record, secret: secret)
                }
                .buttonStyle(.borderedProminent)
                .disabled(record.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cookie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}

