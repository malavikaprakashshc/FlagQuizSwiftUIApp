//
//  ChallengeViewModel.swift
//  TestApp01
//
//  Created by Malavika on 20/09/25.
//

import Foundation
import CoreData
import SwiftUI

enum Phase {
    case notScheduled
    case preStart
    case question
    case interval
    case gameOver
}

@MainActor
class ChallengeViewModel: ObservableObject {
    @Published var questions: [ChallengeQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var score = 0
    @Published var phase: Phase = .notScheduled
    @Published var countdownText = ""
    @Published var questionCountdownText = ""
    @Published var selectedOption: Int? = nil
    @Published var revealed: Bool = false

    private var context: NSManagedObjectContext
    private var timer: Timer?
    private var scheduledTime: Date?
    
    private var preStartRemaining: Int = 0
    private var questionRemaining: Int = 0

    var percentageScore: Int {
        return score * 10
    }

    var maxScore: Int {
        return questions.count * 10
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        loadQuestions()
    }
  
    func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "flags", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONDecoder().decode(RootQuestions.self, from: data) else {
            print("⚠️ Could not load flags.json")
            return
        }

        self.questions = root.questions.enumerated().compactMap { (i, raw) in
            let options = raw.countries.map { $0.country_name }
            let correctIndex = raw.countries.firstIndex { $0.id == raw.answer_id } ?? 0
            let flagUrl = "https://flagcdn.com/w320/\(raw.country_code.lowercased()).png"

            return ChallengeQuestion(
                id: i + 1,
                country: options[correctIndex],
                countryCode: raw.country_code,
                flagUrl: flagUrl,
                options: options,
                correctOptionIndex: correctIndex
            )
        }
    }
    
    func scheduleChallenge(at date: Date) {
        scheduledTime = date
        phase = .preStart
        startPreStartCountdown(to: date)
    }
    
    func startPreStartCountdown(to date: Date) {
           timer?.invalidate()

           preStartRemaining = max(0, Int(date.timeIntervalSinceNow))
           updateCountdownText(preStartRemaining)

           timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
               guard let self = self else { return }
               Task { @MainActor in
                   self.preStartRemaining -= 1
                   self.updateCountdownText(self.preStartRemaining)

                   if self.preStartRemaining <= 0 {
                       t.invalidate()
                       self.startChallenge()
                   }
               }
           }
       }

    private func updateCountdownText(_ remaining: Int) {
        if remaining > 0 {
            countdownText = String(format: "%02d:%02d", remaining / 60, remaining % 60)
        } else {
            countdownText = "00:00"
        }
    }
    
    private func startChallenge() {
        currentQuestionIndex = 0
        score = 0
        phase = .question
        showQuestion()
    }

    private func showQuestion() {
        selectedOption = nil
        revealed = false

        questionRemaining = 30
        questionCountdownText = "00:30"

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self = self else { return }
            Task { @MainActor in
                self.questionRemaining -= 1
                self.questionCountdownText = "00:\(String(format: "%02d", self.questionRemaining))"
                if self.questionRemaining <= 0 {
                    t.invalidate()
                    self.revealAnswer()
                }
            }
        }
    }

    private func revealAnswer() {
        checkAnswer()
        revealed = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.nextQuestion()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func nextQuestion() {
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            showQuestion()
        } else {
            phase = .gameOver
        }
    }

    func selectOption(_ index: Int) {
        guard !revealed else { return }
        selectedOption = index
    }

    func checkAnswer() {
        guard !revealed, let selected = selectedOption else { return }
        if selected == questions[currentQuestionIndex].correctOptionIndex {
            score += 1
        }
    }
}
