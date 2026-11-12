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
    private let names = ["rain1", "rain2", "rain3"]

    init() {
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates()
        }
    }

    func add(in size: CGSize, atCenter: Bool) {
        if size.width <= 0 || size.height <= 0 { return }
        if drops.count >= 60 { return }
        let s = CGFloat.random(in: 80...160)
        let name = names[Int.random(in: 0..<names.count)]
        var px = size.width / 2
        var py = size.height / 2
        if !atCenter {
            px = CGFloat.random(in: s...max(s, size.width - s))
            py = CGFloat.random(in: s...max(s, size.height - s))
        }
        let drop = Drop(
            picture: loadRainImage(name),
            x: px,
            y: py,
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
            }
            d.angle += Double(d.vx) * 0.6
            list[i] = d
        }
        drops = list
    }
}
