//
//  ChallengeQuestion.swift
//  TestApp01
//
//  Created by Malavika on 20/09/25.
//

import Foundation

struct ChallengeQuestion: Identifiable {
    let id: Int
    let country: String
    let countryCode: String
    let flagUrl: String
    let options: [String]
    let correctOptionIndex: Int
}


struct RawCountry: Decodable {
    let country_name: String
    let id: Int
}

struct RawQuestion: Decodable {
    let answer_id: Int
    let countries: [RawCountry]
    let country_code: String
}

struct RootQuestions: Decodable {
    let questions: [RawQuestion]
}

