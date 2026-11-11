import SwiftUI
import UIKit

func loadRainImage(_ name: String) -> UIImage {
    if let path = Bundle.main.path(forResource: name, ofType: "jpg"),
       let img = UIImage(contentsOfFile: path) {
        return img
    }
    return UIImage()
}

struct Drop: Identifiable {
    let id = UUID()
    let image: String
    let x: CGFloat
    let size: CGFloat
    let angle: Double
    let spin: Double
    let duration: Double
    let delay: Double
}

struct RainDrop: View {
    let drop: Drop
    let width: CGFloat
    let height: CGFloat
    @State private var fallen = false

    var body: some View {
        Image(uiImage: loadRainImage(drop.image))
            .resizable()
            .scaledToFit()
            .frame(width: drop.size, height: drop.size)
            .rotationEffect(.degrees(fallen ? drop.angle + drop.spin : drop.angle))
            .position(x: drop.x * width, y: fallen ? height + 400 : -400)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: drop.duration)
                        .delay(drop.delay)
                        .repeatForever(autoreverses: false)
                ) {
                    fallen = true
                }
            }
    }
}

struct ContentView: View {
    @State private var drops: [Drop] = makeDrops()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                

