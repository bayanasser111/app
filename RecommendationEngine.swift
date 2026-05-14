import SwiftUI
import UserNotifications

struct addCustomRoutine: View {
    @EnvironmentObject var appState: AppState

    @AppStorage("isReminderOn") private var reminderOn = false
    @AppStorage("reminderTime") private var reminderTime = Date()
    
    @Binding var isShowingSheet: Bool
    
    // Routine being constructed
    @State private var tempRoutineId: String = UUID().uuidString
    @State private var routineCreatedInStore: Bool = false
    
    @State private var routineName: String = ""
    @State private var showValidationError = false
    
    // New: Deadline state (default = now + 1 month)
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    
    // AddProductSheet presentation
    @State private var isShowingAddProductSheet = false
    
    // Helper to access the temp routine live from AppState
    private var tempRoutine: Routine? {
        appState.routines.first(where: { $0.id == tempRoutineId })
    }
    private var tempRoutineProducts: [RoutineStep] {
        (tempRoutine?.products ?? []).sorted { $0.order < $1.order }
    }
    
    private func timeString(from date: Date?) -> String {
        guard let date else { return "" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "ar")
        df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Close
                        HStack {
                            Spacer()
                            Button(action: {
                                // If user closes without saving, remove the temporary routine (only if still placeholder name)
                                cleanupTempRoutineIfNeeded()
                                isShowingSheet = false
                            }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Routine Name
                        VStack(alignment: .leading, spacing: 5) {

                            TextField("ادخل اسم الروتين", text: $routineName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                            if showValidationError && routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text("الرجاء إدخال اسم الروتين")
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Deadline picker // make the user select the count of the time not the date or any simple way
                        VStack(alignment: .leading, spacing: 10) {
                            Text("تاريخ الانتهاء ( بعد شهر)")
                            DatePicker("", selection: $deadline, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                        .cornerRadius(12)
                        
                        Text("قم بإضافة منتجات لروتينك (اختياري)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Add Product Button (uses AddProductSheet)
                        HStack {
                            Button(action: {
                                isShowingAddProductSheet = true
                            }) {
                                HStack(spacing: 6) {
                                    Text("إضافة منتجات")
                                    Image(systemName: "plus")
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.lightblue)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                )
                           
                            }
                            .foregroundColor(.black)
                            Spacer()
                        }
                        
                        // Routine Reminder (for the whole routine)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("احصل على إشعار لإكمال روتينك")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Spacer()
                                Toggle("", isOn: $reminderOn)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                        // Products List (live from temp routine)
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(tempRoutineProducts) { product in
                                routineProductView(
                                    name: product.productName,
                                    brand: product.category,
                                    type: product.category,
                                    time: timeString(from: product.reminderTime)
                                )
                            }
                            if tempRoutineProducts.isEmpty {
                                Text("لا توجد منتجات في الروتين حاليًا. يمكنك إضافة منتجات لاحقًا.")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        
                        Spacer(minLength: 50)
                        
                        // Add Routine Button
                        Button(action: addRoutineTapped) {
                            Text("اضافة الروتين")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .cornerRadius(12)
                                .background(Color.lightblue)
                                .foregroundColor(.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                )
                        }
                    }
                    .padding()
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        // Present AddProductSheet bound to the temp routine id
        .sheet(isPresented: $isShowingAddProductSheet) {
            AddProductSheet(isShowingSheet: $isShowingAddProductSheet, routineId: tempRoutineId)
                .environmentObject(appState)
        }
        .onAppear {
            ensureTempRoutineExists()
        }
        .onDisappear {
            // If the user leaves without saving, clean up (only if still placeholder name)
            if isShowingSheet == false {
                cleanupTempRoutineIfNeeded()
            }
        }
    }
    
    // Ensure temporary routine exists in AppState so AddProductSheet can append products to it
    private func ensureTempRoutineExists() {
        if appState.routines.first(where: { $0.id == tempRoutineId }) == nil {
            // Default reminder time string "HH:mm" from current reminderTime
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: reminderTime)
            let temp = Routine(
                id: tempRoutineId,
                name: "روتين جديد",
                icon: "sparkles",
                description: "روتين مخصص (قيد الإنشاء)",
                products: [],
                reminderTime: timeString,
                isDeletable: true,
                deadline: deadline
            )
            appState.addRoutine(temp)
            routineCreatedInStore = true
        } else {
            routineCreatedInStore = true
        }
    }
    
    private func cleanupTempRoutineIfNeeded() {
        // Remove the temp routine only if it still has the placeholder name (unsaved draft).
        guard routineCreatedInStore else { return }
        if let r = appState.routines.first(where: { $0.id == tempRoutineId }) {
            if r.name == "روتين جديد" || r.name == "روتين مخصص" {
                appState.deleteRoutine(r)
            }
        }
        routineCreatedInStore = false
    }
    
    private func addRoutineTapped() {
        let trimmed = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showValidationError = true
            return
        }
        
        // Convert routine reminder time to "HH:mm"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let routineTimeString = formatter.string(from: reminderTime)
        
        // Update the existing temp routine with final details (save even with zero products)
        if var routine = appState.routines.first(where: { $0.id == tempRoutineId }) {
            routine.name = trimmed
            routine.description = "روتين مخصص"
            routine.icon = "sparkles"
            routine.reminder.enabled = reminderOn
            routine.reminder.time = routineTimeString
            routine.deadline = deadline
            appState.updateRoutine(routine) // AppState will reschedule notifications
        }
        
        isShowingSheet = false
    }
}

struct routineProductView: View {
    var name: String
    var brand: String
    var type: String
    var time: String
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "drop")
                        .font(.title2)
                        .foregroundColor(.gray)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.headline)
                Text(brand).font(.subheadline).foregroundColor(.gray)
                Text(type).font(.subheadline).foregroundColor(.gray)
                if !time.isEmpty {
                    Text(time).font(.subheadline).foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: {
                //
            }) {
                Image(systemName: "xmark").foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    addCustomRoutine(isShowingSheet: .constant(true))
        .environmentObject(AppState())
}
