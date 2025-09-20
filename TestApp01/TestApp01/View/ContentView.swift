//
//  ContentView.swift
//  TestApp01
//
//  Created by Malavika on 20/09/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var viewModel: ChallengeViewModel
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ChallengeViewModel(context: context))
    }
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.themeOrange)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
            
            switch viewModel.phase {
            case .notScheduled:
                ChallengeNotScheduledView(viewModel: viewModel)
                
            case .preStart:
                VStack(spacing: 10) {
                    ChallengeHeaderView(countdownText: $viewModel.countdownText)
                    Divider()
                    VStack {
                        TextView(text: "WILL START IN", fontSize: 18, fontType: .bold, color: .black)
                        TextView(text: viewModel.countdownText, fontSize: 23, fontType: .bold, color: .gray)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                }
                .background(.grayBg)
                
            case .question:
                VStack(spacing: 10) {
                    ChallengeHeaderView(countdownText: $viewModel.questionCountdownText)
                    Divider()
                    QuestionCardView(viewModel: viewModel)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.grayBg)
                )
                
            case .interval:
                Text("Next question soon...")
                
            case .gameOver:
                VStack(spacing: 10) {
                    ChallengeHeaderView(countdownText: .constant("00:00"))
                    Divider()
                    VStack {
                        TextView(text: "GAME OVER", fontSize: 30, fontType: .bold, color: .black)
                        HStack {
                            TextView(text: "SCORE: ", fontSize: 20, fontType: .semibold, color: .themeOrange)
                            TextView(text: "\(viewModel.percentageScore)/\(viewModel.maxScore)", fontSize: 30, fontType: .bold, color: .black)
                        }
                    }
                    .frame(height: 200, alignment: .center)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.grayBg)
                )
            }
            Spacer()
        }
        .ignoresSafeArea(.all)
    }
    
}

//MARK: Common Header
struct ChallengeHeaderView: View {
    @Binding var countdownText: String

    var body: some View {
        HStack(spacing: 50) {
            TextView(text: countdownText, fontSize: 18, fontType: .semibold, color: .white)
                .padding()
                .background {
                    Image("bgRectBlack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 60)
                }
            TextView(text: "FLAGS CHALLENGE", fontSize: 22, fontType: .heavy, color: .themeOrange)
                .shadow(color: .black, radius: 2, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//MARK: Initial Countdown
struct ChallengeNotScheduledView: View {
    @ObservedObject var viewModel: ChallengeViewModel

    @State var countdownText: String = "00:00"
    @State var scheduledTime: Date? = nil
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            ChallengeHeaderView(countdownText: $countdownText)
            Divider()
            HStack {
                TextView(text: "CHALLENGE", fontSize: 18, fontType: .semibold, color: .black)
                TextView(text: "SCHEDULE", fontSize: 20, fontType: .heavy, color: .black)
                    .shadow(radius: 9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
            CustomTimePicker(onSave: { time in
                scheduledTime = time
                viewModel.scheduleChallenge(at: time)
            })
        }
        .padding(.vertical, 2)
        .padding(.horizontal, -2)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.black, lineWidth: 2)
        }
        .padding(.horizontal, 10)
        .onReceive(timer) { _ in
            guard let scheduledTime else { return }
            let remaining = Int(scheduledTime.timeIntervalSinceNow)
            if remaining > 0 {
                countdownText = String(format: "%02d:%02d", remaining / 60, remaining % 60)
            } else {
                countdownText = "00:00"
            }
        }
    }
}

//MARK: Time Picker
struct CustomTimePicker: View {
    enum Field { case hourTens, hourOnes, minuteTens, minuteOnes, secondTens, secondOnes }
    
    var onSave: (Date) -> Void
    
    @State private var hourTens: String = ""
    @State private var hourOnes: String = ""
    @State private var minuteTens: String = ""
    @State private var minuteOnes: String = ""
    @State private var secondTens: String = ""
    @State private var secondOnes: String = ""
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 24) {
                VStack {
                    Text("Hour")
                    HStack(spacing: 4) {
                        DigitField(text: $hourTens, focusedField: $focusedField, thisField: .hourTens, nextField: .hourOnes)
                        DigitField(text: $hourOnes, focusedField: $focusedField, thisField: .hourOnes, nextField: .minuteTens)
                    }
                }
                VStack {
                    Text("Minute")
                    HStack(spacing: 4) {
                        DigitField(text: $minuteTens, focusedField: $focusedField, thisField: .minuteTens, nextField: .minuteOnes)
                        DigitField(text: $minuteOnes, focusedField: $focusedField, thisField: .minuteOnes, nextField: .secondTens)
                    }
                }
                VStack {
                    Text("Second")
                    HStack(spacing: 4) {
                        DigitField(text: $secondTens, focusedField: $focusedField, thisField: .secondTens, nextField: .secondOnes)
                        DigitField(text: $secondOnes, focusedField: $focusedField, thisField: .secondOnes, nextField: nil)
                    }
                }
            }
            
            Button(action: {
                let hours = (Int(hourTens) ?? 0) * 10 + (Int(hourOnes) ?? 0)
                let minutes = (Int(minuteTens) ?? 0) * 10 + (Int(minuteOnes) ?? 0)
                let seconds = (Int(secondTens) ?? 0) * 10 + (Int(secondOnes) ?? 0)
                
                let totalSeconds = hours * 3600 + minutes * 60 + seconds
                let targetTime = Date().addingTimeInterval(TimeInterval(totalSeconds))
                onSave(targetTime) // send to parent
            }) {
                Text("Save")
                    .fontWeight(.bold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear { focusedField = .hourTens }
    }
}

//MARK: Time Picker Fields
struct DigitField: View {
    @Binding var text: String
    @FocusState.Binding var focusedField: CustomTimePicker.Field?
    
    let thisField: CustomTimePicker.Field
    let nextField: CustomTimePicker.Field?
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .focused($focusedField, equals: thisField)
            .multilineTextAlignment(.center)
            .frame(width: 40, height: 50)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(6)
            .font(.title2)
            .placeholder(when: text.isEmpty) {
                Text("0").foregroundColor(.gray)
            }
            .onChange(of: text) { oldValue, newValue in

                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }

                if !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: newValue)) {
                    text = oldValue
                }

                if newValue.count == 1 {
                    if let next = nextField {
                        focusedField = next
                    } else {
                        focusedField = nil
                    }
                }
            }
    }
}

//MARK: Quiz Cards
struct QuestionCardView: View {
    @ObservedObject var viewModel: ChallengeViewModel
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            HStack(spacing: 40) {
                TextView(text: "\(viewModel.currentQuestionIndex + 1)", fontSize: 14, fontType: .semibold, color: .white)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.themeOrange)
                            .stroke(.black)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 10, topTrailingRadius: 10, style: .continuous)
                            .fill(.black)
                    }
                TextView(text: "Guess the Country from the Flag ?".uppercased(), fontSize: 14, fontType: .semibold, color: .black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 40) {
                if let question = viewModel.questions[safe: viewModel.currentQuestionIndex] {
                    
                    AsyncImage(url: URL(string: question.flagUrl)) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 80, height: 50)
                    
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(question.options.indices, id: \.self) { i in
                            Button(action: { viewModel.selectOption(i) }) {
                                VStack(spacing: 4) {
                                    Text(question.options[i])
                                        .font(.system(size: 13))
                                        .foregroundStyle(.black)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity, minHeight: 20)
                                        .padding(10)
                                        .background(
                                            viewModel.selectedOption == i && !viewModel.revealed
                                                ? Color.gray.opacity(0.3)
                                            : viewModel.revealed && viewModel.selectedOption == i && i != question.correctOptionIndex
                                                ? Color.themeOrange
                                            : Color.clear
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    viewModel.revealed && i == question.correctOptionIndex
                                                        ? Color.green
                                                        : Color.gray,
                                                    lineWidth: 2
                                                )
                                        )
                                        .cornerRadius(8)
                                    
                                    if viewModel.revealed {
                                        if i == question.correctOptionIndex {
                                            Text("CORRECT")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else if viewModel.selectedOption == i {
                                            Text("WRONG")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else {
                                            Text("")
                                                .foregroundColor(.clear)
                                        }
                                    }
                                }
                                .frame(height: 60)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

