//
//  RecommendationEngine.swift
//  Lume
//
//  Scores products using user answers + ingredients.
//

import Foundation

// MARK: - Answers captured from RecommendationQuizView
struct RecommendationAnswers: Codable, Equatable {
    enum PrimaryGoal: String, Codable {
        case acnePores = "goal_acne_pores"
        case pigmentation = "goal_pigmentation"
        case antiAging = "goal_anti_aging"
        case hydration = "goal_hydration"
    }
    enum UsageTime: String, Codable {
        case morning = "time_morning"
        case night = "time_night"
        case both = "time_both"
    }
    enum ProductTypePref: String, Codable {
        case cleanser = "product_cleanser"
        case serum = "product_serum"
        case moisturizer = "product_moisturizer"
        case sunscreen = "product_sunscreen"
    }
    
    // From Q1 (type_*), we will rely primarily on AppState.skinType but keep the raw in case needed
    var rawSkinTypeAnswer: String?
    // From Q2
    var primaryGoal: PrimaryGoal?
    // From Q3
    var isIrritatedNow: Bool
    // From Q4
    var usageTime: UsageTime?
    // From Q5
    var productTypePreference: ProductTypePref?
    // From Q6
    var hasAllergy: Bool
    // Optional specific avoid list (could be filled later via UI)
    var avoidIngredients: Set<String>
    
    init(
        rawSkinTypeAnswer: String? = nil,
        primaryGoal: PrimaryGoal? = nil,
        isIrritatedNow: Bool = false,
        usageTime: UsageTime? = nil,
        productTypePreference: ProductTypePref? = nil,
        hasAllergy: Bool = false,
        avoidIngredients: Set<String> = []
    ) {
        self.rawSkinTypeAnswer = rawSkinTypeAnswer
        self.primaryGoal = primaryGoal
        self.isIrritatedNow = isIrritatedNow
        self.usageTime = usageTime
        self.productTypePreference = productTypePreference
        self.hasAllergy = hasAllergy
        self.avoidIngredients = avoidIngredients
    }
}

// MARK: - RecommendationEngine
struct RecommendationEngine {
    // Map concerns/goals to helpful ingredients
    private static let goalToPositiveIngredients: [RecommendationAnswers.PrimaryGoal: Set<String>] = [
        .acnePores: ["Salicylic Acid", "Niacinamide", "Zinc", "Tea Tree", "BHA", "Azelaic Acid"],
        .pigmentation: ["Ascorbic Acid", "Vitamin C", "Niacinamide", "Arbutin", "Kojic Acid", "Tranexamic Acid"],
        .antiAging: ["Retinol", "Retinoid", "Peptides", "Vitamin C", "Bakuchiol"],
        .hydration: ["Hyaluronic Acid", "Glycerin", "Squalane", "Ceramides", "Panthenol"]
    ]
    
    // Very light skin-type compatibility heuristics
    private static func skinTypeCompatibilityScore(product: Product, userSkinType: SkinType) -> Double {
        // If product lists compatible skin types, prefer matches
        let productTypes = Set(product.skinType.map { $0.lowercased() })
        let st = userSkinType.rawValue.lowercased()
        if productTypes.contains("all types".lowercased()) { return 0.6 }
        if productTypes.contains(st) { return 1.0 }
        // Otherwise neutral
        return 0.4
    }
    
    // Penalize potentially irritating ingredients if user is irritated now
    private static let generallyIrritating: Set<String> = ["Fragrance", "Alcohol", "Essential Oil", "Menthol", "Peppermint"]
    
    // Night-only ingredients if the user selected morning only
    private static let nightActives: Set<String> = ["Retinol", "Retinoid", "AHA", "Glycolic Acid", "Lactic Acid", "TCA", "Peel"]
    
    // Category mapping to align product type preference
    private static func categoryPreferenceScore(product: Product, pref: RecommendationAnswers.ProductTypePref) -> Double {
        switch pref {
        case .cleanser: return product.category.localizedCaseInsensitiveContains("cleanser") ? 1.0 : 0.0
        case .serum: return product.category.localizedCaseInsensitiveContains("serum") ? 1.0 : 0.0
        case .moisturizer: return product.category.localizedCaseInsensitiveContains("moisturizer") ? 1.0 : 0.0
        case .sunscreen: return product.category.localizedCaseInsensitiveContains("sunscreen") ? 1.0 : 0.0
        }
    }
    
    static func score(product: Product, userSkinType: SkinType, answers: RecommendationAnswers) -> Double {
        var score: Double = 0
        
        // Skin type compatibility
        score += 2.0 * skinTypeCompatibilityScore(product: product, userSkinType: userSkinType)
        
        // Goal ingredient matches
        if let goal = answers.primaryGoal, let positives = goalToPositiveIngredients[goal] {
            let productIngs = Set(product.ingredients.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            let matches = positives.intersection(productIngs)
            score += Double(matches.count) * 1.5
        }
        
        // Category preference
        if let pref = answers.productTypePreference {
            score += 1.0 * categoryPreferenceScore(product: product, pref: pref)
        }
        
        // Reduce if the user is irritated now and product has generally irritating ingredients
        if answers.isIrritatedNow {
            let productIngs = Set(product.ingredients)
            if !generallyIrritating.intersection(productIngs).isEmpty {
                score -= 1.5
            }
        }
        
        // If morning only, reduce night actives
        if answers.usageTime == .morning {
            let productIngs = Set(product.ingredients)
            if !nightActives.intersection(productIngs).isEmpty {
                score -= 1.0
            }
        }
        
        // Allergies / avoid list
        if answers.hasAllergy, !answers.avoidIngredients.isEmpty {
            let productIngs = Set(product.ingredients)
            if !answers.avoidIngredients.intersection(productIngs).isEmpty {
                score -= 3.0
            }
        }
        
        // Use rating as a small tie-breaker
//        score += product.rating * 0.2
        
        return score
    }
    
    static func recommend(products: [Product], userSkinType: SkinType, answers: RecommendationAnswers, count: Int) -> [Product] {
        let ranked = products
            .map { (product: $0, score: score(product: $0, userSkinType: userSkinType, answers: answers)) }
            .sorted { a, b in
                if a.score == b.score {
                    // Secondary tie-breaker: prefer products with more benefits listed
                    return a.product.benefits.count > b.product.benefits.count
                }
                return a.score > b.score
            }
            .map { $0.product }
        return Array(ranked.prefix(count))
    }
}
