import SwiftUI
import UIKit
import Combine

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Skin type card
                SkinTypeProfileCardArabic(skinType: appState.skinType)
                    .environmentObject(appState)
                
                // Current routine card
                CurrentRoutineCardArabic()
                    .environmentObject(appState)
                
                // Next step dynamic
                NextStepDynamicView()
                    .environmentObject(appState)
                
                // Weekly progress
                WeeklyProgressCardArabic()
                    .environmentObject(appState)
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .environment(\.layoutDirection, .rightToLeft)
    
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .trailing, spacing: 6) {
                Text("يمكنك مراقبة ادائك من هنا")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: Skin Type Card
struct SkinTypeProfileCardArabic: View {
    @EnvironmentObject var appState: AppState
    @State private var showSkinQuiz = false
    let skinType: SkinType
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text("نوع بشرتك هو :")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
            }
            
            HStack {
                Text(skinType.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                
                Button(action: { showSkinQuiz = true }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(skinType.color)
                }
                .sheet(isPresented: $showSkinQuiz) {
                    SkinQuizView(isShowingSheet: $showSkinQuiz, startFullQuiz: true)
                        .environmentObject(appState)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: Current Routine Card
struct CurrentRoutineCardArabic: View {
    @EnvironmentObject var appState: AppState
    @State private var isShowingAddRoutineSheet = false
    @State private var showDeleteConfirmId: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(" روتيني ")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(appState.routines) { routine in
                    RoutineRowArabic(
                        routine: routine,
                        isShowingDeleteAlert: Binding(
                            get: { showDeleteConfirmId == routine.id },
                            set: { newValue in
                                showDeleteConfirmId = newValue ? routine.id : nil
                            }
                        ),
                        onRequestDelete: { showDeleteConfirmId = routine.id },
                        onConfirmDelete: { appState.deleteRoutine(routine) }
                    )
                }
            }
            
            Button(action: { isShowingAddRoutineSheet = true }) {
                Text("اضافة روتين جديد")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.lightblue)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            }
            .sheet(isPresented: $isShowingAddRoutineSheet) {
                addCustomRoutine(isShowingSheet: $isShowingAddRoutineSheet)
                    .environmentObject(appState)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
        )
    }
}

private struct RoutineRowArabic: View {
    let routine: Routine
    @Binding var isShowingDeleteAlert: Bool
    let onRequestDelete: () -> Void
    let onConfirmDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Text(routine.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(routine.reminderTime ?? "")
                        .font(.caption2)
                        .foregroundColor(.black)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(Color.clear)
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
               
                    if routine.isDeletable {
                        Button(role: .destructive) { onRequestDelete() } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.black)
                        }
                        .alert("حذف الروتين؟", isPresented: $isShowingDeleteAlert) {
                            Button("إلغاء", role: .cancel) {}
                            Button("حذف", role: .destructive) { onConfirmDelete() }
                        } message: { Text("سيتم حذف هذا الروتين .") }
                    }
                }
                
               
            }
            Spacer()
            Image(systemName: routine.icon)
                .foregroundColor(.black)
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: Next Step Dynamic
struct NextStepDynamicView: View {
    @EnvironmentObject var appState: AppState
    @State private var now: Date = Date()
    
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack { Text("الخطوة التالية").font(.headline); Spacer()
            }
            
            content
                .padding()
                .background(Color.lightblue)
                .cornerRadius(12)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .onReceive(timer) { date in now = date }
    }
    
    @ViewBuilder
    private var content: some View {
        if let next = appState.nextUpcomingStep(at: now) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(next.step.productName).font(.headline)
                    Spacer()
                    Text(formattedTime(next.time))
                        .font(.subheadline)
                        .foregroundColor(.lightblue)
                }
                Text(next.routine.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Spacer()
                    let isCompleted = appState.isStepCompletedToday(
                        routineId: next.routine.id,
                        stepId: next.step.id
                    )
                    Button(action: {
                        appState.toggleStepCompletedToday(
                            routineId: next.routine.id,
                            stepId: next.step.id
                        )
                        now = Date()
                    }) {
                        HStack {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(isCompleted ? "تم الإنجاز" : "أنجز الآن")
                        }
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isCompleted ? Color.lightblue : Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isCompleted)
                }
            }
        } else {
            HStack {
                Spacer()
                Text("لقد اكملت روتينك اليومي")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ar")
        df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
}

// MARK: Weekly Progress Card
struct WeeklyProgressCardArabic: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            HStack {
                Spacer()
                HStack(spacing: 115) {
                    Text("تقدم اليوم")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Image(systemName: "rosette")
                        .foregroundColor(.pink)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(appState.routines) { routine in
                    let total = routine.products.count
                    let completed = routine.products.filter {
                        appState.isStepCompletedToday(routineId: routine.id, stepId: $0.id)
                    }.count
                    let value = total > 0 ? Double(completed)/Double(total) : 0
                    ProgressRowArabic(title: routine.name, completedText: "اكتمل \(completed)/\(total)", value: value)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }
}

struct ProgressRowArabic: View {
    let title: String
    let completedText: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(completedText)
                    .font(.subheadline)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    Capsule()
                        .fill(Color.lightblue)
                        .frame(width: max(0, CGFloat(value) * geo.size.width), height: 12)
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(AppState())
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "ar"))
    }
}

