//
//  AddStaffSheet.swift
//  Boutique Manager
//
//  Created by Akhand Pratap Singh on 25/06/26.
//

import SwiftUI

struct AddStaffSheet: View {
    let storeID: UUID
    var onSave: (User, String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    
    enum Field {
        case email, phone
    }
    @FocusState private var focusedField: Field?
    
    @State private var hasEmailLostFocus = false
    @State private var hasPhoneLostFocus = false

    // Validation
    private var isEmailValid: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private var isPhoneValid: Bool {
        let phoneRegex = "^[0-9+() -]{7,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePred.evaluate(with: phoneNumber)
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isEmailValid &&
        isPhoneValid &&
        password.count >= 6
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Info")) {
                    HStack(spacing: 12) {
                        TextField("First Name", text: $firstName)
                        Divider()
                        TextField("Last Name", text: $lastName)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            
                        if hasEmailLostFocus && !email.isEmpty && !isEmailValid {
                            Text("Please enter a valid email address.")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Phone Number", text: $phoneNumber)
                            .focused($focusedField, equals: .phone)
                            .keyboardType(.phonePad)
                            
                        if hasPhoneLostFocus && !phoneNumber.isEmpty && !isPhoneValid {
                            Text("Please enter a valid phone number (7-15 digits).")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                        
                    SecureField("Temporary Password", text: $password)
                }
                .onChange(of: focusedField) { newValue in
                    if newValue != .email && !email.isEmpty {
                        hasEmailLostFocus = true
                    }
                    if newValue != .phone && !phoneNumber.isEmpty {
                        hasPhoneLostFocus = true
                    }
                }

                Section {
                    HStack {
                        Label("Role", systemImage: "person.badge.key")
                        Spacer()
                        Text("Sales Associate")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Store", systemImage: "storefront")
                        Spacer()
                        Text("Your Store")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Assignment")
                } footer: {
                    Text("Role and store are assigned automatically.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.themeBackground)
            .navigationTitle("Add Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newUser = User(
                            id: UUID(),
                            firstName: firstName.trimmingCharacters(in: .whitespaces),
                            lastName: lastName.trimmingCharacters(in: .whitespaces),
                            email: email.trimmingCharacters(in: .whitespaces),
                            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespaces),
                            role: .salesAssociate,
                            assignedStoreID: storeID,
                            isActive: false
                        )
                        onSave(newUser, password)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
}

#Preview {
    AddStaffSheet(storeID: UUID()) { _,_  in }
}
