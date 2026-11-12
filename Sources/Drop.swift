import SwiftUI
import UIKit
import CoreMotion

struct Drop: Identifiable {
    let id = UUID()
    let picture: UIImage
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var angle: Double
    let size: CGFloat
}

func loadRainImage(_ name: String) -> UIImage {
    if let path = Bundle.main.path(forResource: name, ofType: "jpg"),
       let img = UIImage(contentsOfFile: path) {
        return img
    }
    return UIImage()
}

final class World: ObservableObject {
    @Published var drops: [Drop] = []
    private let motion = CMMotionManager()
    private let pictures: [UIImage] = ["rain1", "rain2", "rain3"].map { loadRainImage($0) }

    // No limit. Lower this number if you ever want a cap.
    private let maxDrops = Int.max

    init() {
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates()
        }
    }

    func add(in size: CGSize, atCenter: Bool) {
        // Taps call this with atCenter false, so they do nothing.
        if !atCenter { return }
        if size.width <= 0 || size.height <= 0 { return }
        if !drops.isEmpty { return }
        let s = CGFloat.random(in: 80...160)
        let drop = Drop(
            picture: pictures[Int.random(in: 0..<pictures.count)],
            x: size.width / 2,
            y: size.height / 2,
            angle: Double.random(in: 0...360),
            size: s
        )
        drops.append(drop)
    }

    func step(in size: CGSize) {
        if size.width <= 0 || size.height <= 0 { return }
        var gx: CGFloat = 0
        var gy: CGFloat = 0
        if let g = motion.deviceMotion?.gravity {
            gx = CGFloat(g.x)
            gy = CGFloat(-g.y)
        }

        let maxSpeed: CGFloat = 28
        let minKick: CGFloat = 10
        let boost: CGFloat = 1.2

        var list = drops
        var born: [Drop] = []

        for i in list.indices {
            var d = list[i]
            d.vx = (d.vx + gx * 0.4) * 0.995
            d.vy = (d.vy + gy * 0.4) * 0.995

            if d.vx > maxSpeed { d.vx = maxSpeed }
            if d.vx < -maxSpeed { d.vx = -maxSpeed }
            if d.vy > maxSpeed { d.vy = maxSpeed }
            if d.vy < -maxSpeed { d.vy = -maxSpeed }

            d.x += d.vx
            d.y += d.vy

            let r = d.size / 2
            var hit = false

            if d.x < r {
                d.x = r
                d.vx = max(abs(d.vx) * boost, minKick)
                hit = true
            }
            if d.x > size.width - r {
                d.x = size.width - r
                d.vx = -max(abs(d.vx) * boost, minKick)
                hit = true
            }
            if d.y < r {
                d.y = r
                d.vy = max(abs(d.vy) * boost, minKick)
                hit = true
            }
            if d.y > size.height - r {
                d.y = size.height - r
                d.vy = -max(abs(d.vy) * boost, minKick)
                hit = true
            }

            if hit {
                d.angle += Double.random(in: -40...40)
                if list.count + born.count < maxDrops {
                    var baby = Drop(
                        picture: pictures[Int.random(in: 0..<pictures.count)],
                        x: d.x,
                        y: d.y,
                        angle: Double.random(in: 0...360),
                        size: CGFloat.random(in: 80...160)
                    )
                    baby.vx = CGFloat.random(in: -12...12)
                    baby.vy = CGFloat.random(in: -12...12)
                    born.append(baby)
                }
            }
            d.angle += Double(d.vx) * 0.6
            list[i] = d
        }

        list.append(contentsOf: born)
        drops = list
    }
}
