//
//  Models.swift
//  Lume Skincare App
//
//  Data models for the skincare app
//

import Foundation
import SwiftUI

// MARK: - Skin Type
enum SkinType: String, Codable, CaseIterable {
    case dry = "dry"
    case normal = "normal"
    case oily = "oily"
    case combination = "combination"
    
    var title: String {
        switch self {
        case .dry: return "بشرة جافة"
        case .normal: return "بشرة عادية"
        case .oily: return "بشرة دهنية"
        case .combination: return "بشرة مختلطة"
        }
    }
    
    var color: Color {
        switch self {
        case .dry: return .black
        case .normal: return .textcolor
        case .oily: return .textcolor
        case .combination: return .textcolor
        }
    }
    
//    var characteristics: [String] {
//        switch self {
//        case .dry: return ["Tight feeling", "Flaky patches", "Less visible pores", "Matte finish"]
//        case .normal: return ["Well-balanced", "Few imperfections", "Small pores", "Good elasticity"]
//        case .oily: return ["Shiny appearance", "Visible pores", "Prone to breakouts", "Thicker texture"]
//        case .combination: return ["Oily T-zone", "Dry cheeks", "Mixed pore sizes", "Variable texture"]
//        }
//    }
    
    var iconName: String {
        switch self {
        case .dry: return "drop.fill"
        case .normal: return "checkmark.circle.fill"
        case .oily: return "sparkles"
        case .combination: return "circle.fill"
        }
    }
}

// MARK: - Routine Step
struct RoutineStep: Identifiable, Codable {
    var id: String = UUID().uuidString
    var productName: String
    var category: String
    var order: Int
    // Store time-of-day as Date (time component used; normalized to "today" when needed)
    var reminderTime: Date?
}

// MARK: - Reminder Settings
struct ReminderSettings: Codable {
    var enabled: Bool
    var time: String
}

// MARK: - Routine
struct Routine: Identifiable, Codable {
    var id: String
    var name: String
    var icon: String
    var description: String
    var products: [RoutineStep]
    var reminder: ReminderSettings
    var isDeletable: Bool
    var deadline: Date // New: routine deadline
    
    // Convenience routine-level time that mirrors reminder.time
    // This lets UI use routine.reminderTime while keeping ReminderSettings intact.
    var reminderTime: String {
        get { reminder.time }
        set { reminder.time = newValue }
    }
    
    init(
        id: String,
        name: String,
        icon: String,
        description: String,
        products: [RoutineStep] = [],
        reminderTime: String = "08:00",
        isDeletable: Bool = false,
        deadline: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.products = products
        self.reminder = ReminderSettings(enabled: true, time: reminderTime)
        self.isDeletable = isDeletable
        self.deadline = deadline
    }
}

// MARK: - Product
struct Product: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var brand: String
    var category: String
    var skinType: [String]
//    var rating: Double
    var description: String
    var benefits: [String]
    var ingredients: [String]
    var imageURL: String?
}

// MARK: - Product Categories
let productCategories = [
    "منظف",
    "تونر",
    "إسينس",
    "سيروم",
    "كريم للعين",
    "مرطب",
    "واقي شمس",
    "علاج",
    "قناع"
]


// MARK: - Icon Options
enum RoutineIcon: String, CaseIterable {
    case sun = "sun.max.fill"
    case moon = "moon.fill"
    case sparkles = "sparkles"
    
    var displayName: String {
        switch self {
        case .sun: return "Sun"
        case .moon: return "Moon"
        case .sparkles: return "Sparkles"
        }
    }
}

// Removed: All static/sample data (Routine.sampleRoutines, Product.sampleProducts)

