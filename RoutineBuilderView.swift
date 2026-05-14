//
//  logopage.swift
//  Lume
//
//  Created by Nouf Baabbad on 16/05/1447 AH.
//

import Foundation
import SwiftUI

struct logopage: View {
    @EnvironmentObject var appState: AppState
    @State private var showSkinQuiz = false
    @State private var showRecommendationQuiz = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Image("lume")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 330, height: 290)

                Spacer()
                
                Button(action: {
                    showSkinQuiz = true
                }) {
                    Text("ابدأ")
                        .font(.title2)
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 133)
                        .padding(.vertical, 14)
                        .background(Color.lightblue.opacity(0.95))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                
                }
                .padding(.bottom, 40)
                .navigationDestination(isPresented: $showSkinQuiz) {
                    // Present the skin-type quiz. When it completes it sets onboardingStep = .recommendationQuiz
                    SkinQuizView(isShowingSheet: .constant(true))
                        .environmentObject(appState)
                }
            }
            .padding()
            
//            .onChange(of: appState.onboardingStep) { newValue in
//                // When skin quiz completes, automatically show the recommendation quiz
//                if newValue == .recommendationQuiz {
//                    showRecommendationQuiz = true
//                }
//            }
            // Present the recommendation quiz when onboardingStep moves to .recommendationQuiz
//            .fullScreenCover(isPresented: $showRecommendationQuiz) {
//                RecommendationQuizView(isShowingSheet: $showRecommendationQuiz)
//                    .environmentObject(appState)
//            }
        }
    }
}

#Preview {
    logopage().environmentObject(AppState())
}
