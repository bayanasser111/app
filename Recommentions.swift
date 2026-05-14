import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - App State
class AppState: ObservableObject {
    
//    @Published var skinType: SkinType = .dry
    @Published var routines: [Routine] = []
    @Published var products: [Product] = []
    @Published var selectedTab: Tab = .home
//    @Published var skinType: String = ""
    @Published var skinType: SkinType = .normal

    // New: store last recommendation answers
    @Published var recommendationAnswers: RecommendationAnswers? = nil
    
    
    enum Tab {
        case home
        case routine
        case products
    }
    
    // Onboarding flow state
    enum OnboardingStep: String {
        case skinQuiz
        case recommendationQuiz
        case completed
    }
    
    @AppStorage("onboardingStep") private var storedOnboardingStep: String = OnboardingStep.skinQuiz.rawValue
    var onboardingStep: OnboardingStep {
        get { OnboardingStep(rawValue: storedOnboardingStep) ?? .skinQuiz }
        set { storedOnboardingStep = newValue.rawValue }
    }
    
    // Backward compatibility: keep existing flag if you already use it elsewhere
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    // Streak persistence
    @AppStorage("lastOpenDate") private var lastOpenDateString: String = ""
    @AppStorage("storedCurrentStreak") private var storedCurrentStreak: Int = 0
    @AppStorage("storedLongestStreak") private var storedLongestStreak: Int = 0
    
    // Method to complete onboarding
    func completeOnboarding() {
        onboardingStep = .completed
        hasCompletedOnboarding = true
        print("Onboarding completed - switching to main app")
    }
    
    // Per-day completion store: routineId -> Set(stepId)
    @Published private(set) var todaysCompletions: [String: Set<String>] = [:]
    
    init() {
        // Load persisted skin type if available
        if let raw = UserDefaults.standard.string(forKey: "skinType"),
           let stored = SkinType(rawValue: raw) {
            skinType = stored
        }
        // If older flag indicates done, coerce to new model
        if hasCompletedOnboarding {
            onboardingStep = .completed
        }
        
      
        
        // Load routines; if none found, create only Morning and Night with empty products
        loadData()
        if routines.isEmpty {
            routines = defaultEmptyRoutines()
            saveData()
        }
        
        loadCompletionsForToday()
        
        // Load products from JSON; if successful, set products, else leave empty (no samples)
        if let jsonProducts = loadProductsFromJSON(named: "skincare_data_full_extracted") {
            print("JSON loader: Loaded \(jsonProducts.count) products from file.")
            self.products = jsonProducts
        } else {
            print("JSON loader: No JSON found or failed to parse. Leaving products empty.")
            self.products = []
        }
        
        //  Rebuild notifications after data is loaded
        rebuildAllNotifications()
    }
  
    private func dateString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
    
    private func defaultEmptyRoutines() -> [Routine] {
        let oneMonthFromNow = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let morning = Routine(
            id: "morning",
            name: "الروتين الصباحي",
            icon: "sun.max.fill",
            description: "يمكنك رؤية تفاصيل روتينك الصباحي هنا",
            products: [],
            reminderTime: "08:00",
            isDeletable: false,
            deadline: oneMonthFromNow
        )
        let night = Routine(
            id: "night",
            name: "الروتين المسائي",
            icon: "moon.fill",
            description: "يمكنك رؤية تفاصيل روتيك المسائي هنا",
            products: [],
            reminderTime: "21:00",
            isDeletable: false,
            deadline: oneMonthFromNow
        )
        return [morning, night]
    }
    
    // MARK: - Recommendation API
    func setRecommendationAnswers(_ answers: RecommendationAnswers) {
        self.recommendationAnswers = answers
    }
    
    func recommendTopProducts(count: Int = 5) -> [Product] {
        guard let answers = recommendationAnswers else { return [] }
        return RecommendationEngine.recommend(products: products, userSkinType: skinType, answers: answers, count: count)
    }
    
    // MARK: - Routine Management
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveData()
        rebuildAllNotifications()
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
            saveData()
            rebuildAllNotifications()
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        todaysCompletions[routine.id] = nil
        saveData()
        saveCompletionsForToday()
        rebuildAllNotifications()
    }
    
    func addProductToRoutine(routineId: String, product: RoutineStep) {
        if let index = routines.firstIndex(where: { $0.id == routineId }) {
            var routine = routines[index]
            routine.products.append(product)
            routines[index] = routine
            saveData()
            rebuildAllNotifications()
        }
    }
    
    func updateProductInRoutine(routineId: String, product: RoutineStep) {
        if let routineIndex = routines.firstIndex(where: { $0.id == routineId }),
           let productIndex = routines[routineIndex].products.firstIndex(where: { $0.id == product.id }) {
            routines[routineIndex].products[productIndex] = product
            saveData()
            rebuildAllNotifications()
        }
    }
    
    func deleteProductFromRoutine(routineId: String, productId: String) {
        if let index = routines.firstIndex(where: { $0.id == routineId }) {
            routines[index].products.removeAll { $0.id == productId }
            if var set = todaysCompletions[routineId] {
                set.remove(productId)
                todaysCompletions[routineId] = set
                saveCompletionsForToday()
            }
            saveData()
            rebuildAllNotifications()
        }
    }
    
    func resetRoutine(routineId: String) {
        if let index = routines.firstIndex(where: { $0.id == routineId }) {
            routines[index].products = []
            todaysCompletions[routineId] = nil
            saveData()
            saveCompletionsForToday()
            rebuildAllNotifications()
        }
    }
    
    // MARK: - Completion (per-day)
    func isStepCompletedToday(routineId: String, stepId: String) -> Bool {
        todaysCompletions[routineId]?.contains(stepId) ?? false
    }
    
    func toggleStepCompletedToday(routineId: String, stepId: String) {
        var set = todaysCompletions[routineId] ?? Set<String>()
        if set.contains(stepId) {
            set.remove(stepId)
        } else {
            set.insert(stepId)
        }
        todaysCompletions[routineId] = set
        saveCompletionsForToday()
    }
    
    func nextUpcomingStep(at now: Date = Date()) -> (routine: Routine, step: RoutineStep, time: Date)? {
        var best: (Routine, RoutineStep, Date)?
        let calendar = Calendar.current
        for routine in routines {
            for step in routine.products {
                if isStepCompletedToday(routineId: routine.id, stepId: step.id) { continue }
                guard let stepTime = step.reminderTime else { continue }
                let comps = calendar.dateComponents([.hour, .minute], from: stepTime)
                var todayComps = calendar.dateComponents([.year, .month, .day], from: now)
                todayComps.hour = comps.hour
                todayComps.minute = comps.minute
                todayComps.second = 0
                guard let todayAtStepTime = calendar.date(from: todayComps) else { continue }
                if todayAtStepTime >= now {
                    if let currentBest = best {
                        if todayAtStepTime < currentBest.2 {
                            best = (routine, step, todayAtStepTime)
                        }
                    } else {
                        best = (routine, step, todayAtStepTime)
                    }
                }
            }
        }
        return best
    }
    
    // MARK: - Persistence (routines)
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(encoded, forKey: "routines")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "routines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
        } else {
            routines = []
        }
    }
    
    // MARK: - Persistence (per-day completions)
    private var completionsKeyForToday: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let day = formatter.string(from: Date())
        return "completions-\(day)"
    }
    
    private func saveCompletionsForToday() {
        do {
            let encoded = try JSONEncoder().encode(todaysCompletions.mapValues { Array($0) })
            UserDefaults.standard.set(encoded, forKey: completionsKeyForToday)
        } catch {
            print("Failed to save todaysCompletions: \(error)")
        }
    }
    
    private func loadCompletionsForToday() {
        todaysCompletions = [:]
        guard let data = UserDefaults.standard.data(forKey: completionsKeyForToday) else { return }
        do {
            let decoded = try JSONDecoder().decode([String: [String]].self, from: data)
            todaysCompletions = decoded.mapValues { Set($0) }
        } catch {
            print("Failed to load todaysCompletions: \(error)")
        }
    }
}

// MARK: - JSON Loading
extension AppState {
    // DTO matching your JSON keys
    private struct ProductDTO: Decodable {
        let product_name: String
        let product_url: String?
        let product_type: String
        let ingredients: String
        let image_url: String?
    }
    
    private func cleanIngredient(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasSuffix(".") { return String(trimmed.dropLast()) }
        return trimmed
    }
    
    private func deriveBrand(from productName: String) -> String {
        let parts = productName.split(separator: " ").map(String.init)
        if parts.count >= 2 { return parts[0] + " " + parts[1] }
        return parts.first ?? ""
    }
    
    func loadProductsFromJSON(named resourceName: String) -> [Product]? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            print("JSON loader: JSON not found in bundle: \(resourceName).json")
            return nil
        }
        print("JSON loader: Found file at \(url.lastPathComponent)")
        
        guard let data = try? Data(contentsOf: url) else {
            print("JSON loader: Unable to read data.")
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            let dtos = try decoder.decode([ProductDTO].self, from: data)
            print("JSON loader: Decoded \(dtos.count) DTOs.")
            let mapped: [Product] = dtos.map { dto in
                let name = dto.product_name.trimmingCharacters(in: .whitespacesAndNewlines)
                let category = dto.product_type.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let ingredients = dto.ingredients
                    .split(separator: ",")
                    .map { cleanIngredient(String($0)) }
                    .filter { !$0.isEmpty }
                
                let brand = deriveBrand(from: name)
                
                return Product(
                    id: UUID().uuidString,
                    name: name,
                    brand: brand,
                    category: category,
                    skinType: ["جميع البشرات"],
                    description: "",
                    benefits: [],
                    ingredients: ingredients,
                    imageURL: dto.image_url
                )
            }
            print("JSON loader: Created \(mapped.count) Product objects.")
            for sample in mapped.prefix(3) {
                print("JSON loader sample -> \(sample.name) [\(sample.category)] | ingredients: \(sample.ingredients.prefix(3)) | image: \(sample.imageURL ?? "nil")")
            }
            return mapped
        } catch {
            print("JSON loader: Failed to decode JSON: \(error)")
            return nil
        }
    }
}

// MARK: - Notifications
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            print("Error requesting notifications permission: \(error.localizedDescription)")
        } else {
            print("Notifications permission granted: \(granted)")
        }
    }
}

// MARK: - Centralized Notification Scheduling
extension AppState {
    
    // Public entry point to rebuild everything from the current model
    func rebuildAllNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                print("Notifications not authorized; skipping scheduling.")
                return
            }
            // Cancel all we own, then reschedule
            self.cancelAllScheduledNotifications {
                self.scheduleAllFromModel()
            }
        }
    }
    
    private func scheduleAllFromModel() {
        // Schedule per-routine notifications
        for routine in routines {
            if routine.reminder.enabled {
                scheduleRoutineNotification(routine)
            }
            // Schedule per-product notifications
            for step in routine.products {
                if step.reminderTime != nil {
                    scheduleStepNotification(routineId: routine.id, step: step)
                }
            }
        }
    }
    
    private func cancelAllScheduledNotifications(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Filter to identifiers we own (prefix "routine.")
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("routine.") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
            completion()
        }
    }
    
    // MARK: Routine-level daily notification
    func scheduleRoutineNotification(_ routine: Routine) {
        guard let comps = dateComponentsFromHHmm(routine.reminder.time) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = routine.name
        content.body = "حان وقت \(routine.name). أكمل روتينك اليومي."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = comps.hour
        dateComponents.minute = comps.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "routine.\(routine.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule routine \(routine.id): \(error.localizedDescription)")
            } else {
                print("Scheduled routine notification: \(identifier) at \(comps.hour ?? 0):\(comps.minute ?? 0)")
            }
        }
    }
    
    // MARK: Step-level daily notification
    func scheduleStepNotification(routineId: String, step: RoutineStep) {
        guard let time = step.reminderTime else { return }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        
        let content = UNMutableNotificationContent()
        content.title = step.productName
        content.body = "تذكير لمنتج \(step.productName) ضمن \(routineName(for: routineId))."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = comps.hour
        dateComponents.minute = comps.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "routine.\(routineId).step.\(step.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule step \(step.id): \(error.localizedDescription)")
            } else {
                print("Scheduled step notification: \(identifier) at \(comps.hour ?? 0):\(comps.minute ?? 0)")
            }
        }
    }
    
    private func routineName(for routineId: String) -> String {
        routines.first(where: { $0.id == routineId })?.name ?? "روتينك"
    }
    
    private func dateComponentsFromHHmm(_ string: String) -> DateComponents? {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "HH:mm"
        guard let date = df.date(from: string) else { return nil }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return comps
    }
    
    
}
