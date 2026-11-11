import SwiftUI

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
        Image(uiImage: UIImage(named: drop.image + ".jpg") ?? UIImage())
            .resizable()
            .scaledToFit()
            .frame(width: drop.size, height: drop.size)
            .rotationEffect(.degrees(fallen ? drop.angle + drop.spin : drop.angle))
            .position(x: drop.x * width, y: fallen ? height + 400 : -400)
            .onAppear {
                withAnimation(
                    .linear(duration: drop.duration)
                    .delay(drop.delay)
                    .repeatForever(autoreverses: false)
                ) {
                    fallen = true
                }
            }
    }
}

struct ContentView: View {
    @State private var dr
