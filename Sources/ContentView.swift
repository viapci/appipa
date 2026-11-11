import SwiftUI

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

                ForEach(drops) { drop in
                    RainDrop(drop: drop, width: geo.size.width, height: geo.size.height)
                }

                Text("otis woz here <3")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()
                    .shadow(radius: 6)
            }
        }
    }
}
