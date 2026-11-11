import SwiftUI

struct ContentView: View {
    @StateObject private var world = World()
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ForEach(world.drops) { d in
                    Image(uiImage: d.picture)
                        .resizable()
                        .scaledToFit()
                        .frame(width: d.size, height: d.size)
                        .rotationEffect(.degrees(d.angle))
                        .position(x: d.x, y: d.y)
                }

                Text("otis woz here <3")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                    .padding()
                    .shadow(radius: 6)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                world.add(in: geo.size, atCenter: false)
            }
            .onAppear {
                if world.drops.isEmpty {
                    world.add(in: geo.size, atCenter: true)
                }
            }
            .onReceive(timer) { _ in
                world.step(in: geo.size)
            }
        }
    }
}
