import SwiftUI
import UIKit
import CoreMotion

enum Mode {
    case bounce
    case duplicate
}

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

@MainActor
final class World: ObservableObject {
    @Published var drops: [Drop] = []
    private let motion = CMMotionManager()
    private let pictures: [UIImage] = ["rain1", "rain2", "rain3"].map { loadRainImage($0) }

    // Cap for Multiply mode. Int.max means no limit.
    private let maxDrops = Int.max

    // Change to .duplicate to start in Multiply mode.
    private var mode: Mode = .bounce
    private var lastSize: CGSize = .zero
    private var bounceButton: UIButton?
    private var duplicateButton: UIButton?
    private var installAttempts = 0

    init() {
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates()
        }
        installButtons()
    }

    // MARK: Buttons

    private func findWindow() -> UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            if let ws = scene as? UIWindowScene {
                for w in ws.windows {
                    if w.isKeyWindow { return w }
                }
                if let first = ws.windows.first { return first }
            }
        }
        return nil
    }

    private func installButtons() {
        if bounceButton != nil { return }
        guard let window = findWindow() else {
            installAttempts += 1
            if installAttempts < 40 {
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    self?.installButtons()
                }
            }
            return
        }

        let b1 = UIButton(type: .system)
        let b2 = UIButton(type: .system)

        b1.addAction(UIAction { [weak self] _ in
            Task { @MainActor in self?.setMode(.bounce) }
        }, for: .touchUpInside)

        b2.addAction(UIAction { [weak self] _ in
            Task { @MainActor in self?.setMode(.duplicate) }
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [b1, b2])
        stack.axis = .horizontal
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])

        bounceButton = b1
        duplicateButton = b2
        refreshButtons()
    }

    private func makeConfig(title: String, selected: Bool) -> UIButton.Configuration {
        var config: UIButton.Configuration
        if #available(iOS 26.0, *) {
            if selected {
                config = UIButton.Configuration.prominentGlass()
            } else {
                config = UIButton.Configuration.glass()
            }
        } else {
            if selected {
                config = UIButton.Configuration.filled()
            } else {
                config = UIButton.Configuration.tinted()
            }
        }
        config.title = title
        config.buttonSize = .small
        config.cornerStyle = .capsule
        config.imagePadding = 6
        if selected {
            config.image = UIImage(systemName: "checkmark")
        } else {
            config.image = nil
        }
        return config
    }

    private func refreshButtons() {
        bounceButton?.configuration = makeConfig(title: "Bounce", selected: mode == .bounce)
        duplicateButton?.configuration = makeConfig(title: "Multiply", selected: mode == .duplicate)
    }

    private func setMode(_ m: Mode) {
        if mode == m { return }
        mode = m
        refreshButtons()
        drops = []
        if lastSize.width > 0 && lastSize.height > 0 {
            drops = [makeDrop(x: lastSize.width / 2, y: lastSize.height / 2)]
        }
    }

    // MARK: Drops

    private func makeDrop(x: CGFloat, y: CGFloat) -> Drop {
        return Drop(
            picture: pictures[Int.random(in: 0..<pictures.count)],
            x: x,
            y: y,
            angle: Double.random(in: 0...360),
            size: CGFloat.random(in: 80...160)
        )
    }

    func add(in size: CGSize, atCenter: Bool) {
        if size.width <= 0 || size.height <= 0 { return }
        // Taps only add images in Bounce mode.
        if mode == .duplicate && !atCenter { return }
        if atCenter && !drops.isEmpty { return }
        if mode == .bounce && drops.count >= 60 { return }

        var px = size.width / 2
        var py = size.height / 2
        let s: CGFloat = 160
        if !atCenter {
            px = CGFloat.random(in: s...max(s, size.width - s))
            py = CGFloat.random(in: s...max(s, size.height - s))
        }
        drops.append(makeDrop(x: px, y: py))
    }

    func step(in size: CGSize) {
        if size.width <= 0 || size.height <= 0 { return }
        lastSize = size

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
                if mode == .duplicate && list.count + born.count < maxDrops {
                    var baby = makeDrop(x: d.x, y: d.y)
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
