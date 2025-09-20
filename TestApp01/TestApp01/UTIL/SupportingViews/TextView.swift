//
//  TextView.swift
//  TestApp01
//
//  Created by Malavika on 20/09/25.
//

import SwiftUI

struct TextView: View {
    var text: String = ""
    var fontSize: CGFloat = 16
    var fontType: Font.Weight = .regular
    var color: Color = .blue
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: fontType))
            .foregroundColor(color)
    }
}

#Preview {
    TextView()
}
