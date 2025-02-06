//
//  ContentView.swift
//  Cobrowse - SwiftUI
//

import SwiftUI
import CobrowseSDK

struct TestingView: View {

    @State private var text = "Redacted text"
    @State private var username = ""
    @State private var password = ""
    @State private var isAnimating = false
    @State private var scaleFactor: CGFloat = 1.0
    
    var body: some View {
        ScrollView {
            VStack(spacing:10) {
                Text(text)
//                    .cobrowseRedacted()
                
                HStack(spacing: 3) {
                    Text("Hello")
                    Text(text)
//                        .cobrowseRedacted()
                }
                
                Button {
                    text = text == "Redacted text" ? "Updated redacted text" : "Redacted text"
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Button")
//                            .cobrowseRedacted()
                    }
                }
                Button("\(isAnimating ? "Stop" : "Start") animating") {
                    isAnimating.toggle()
                }
                .buttonStyle(.borderedProminent)
//                .cobrowseRedacted()
                
                NavigationLink(destination: TestingView()) {
                    Text("Navigation link")
                }
                
                VStack {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
//                        .cobrowseRedacted()
                }
                .padding(.horizontal, 40)
                
                Image(systemName: "car")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color.yellow)
                    .opacity(0.6)
//                    .cobrowseRedacted()
                    .padding(40)
                    .scaleEffect(isAnimating ? 0.5 : 1.0)
                    .rotationEffect(isAnimating ? .degrees(180) : .zero)
                    .animation(isAnimating ? Animation.easeInOut(duration: 2).repeatForever(autoreverses: true) : .default, value: isAnimating)
                
            }
        }
        .navigationBarTitle("SwiftUI")
        .scaleEffect(scaleFactor)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scaleFactor = value
                }
        )
    }
}

#Preview {
    TestingView()
}
