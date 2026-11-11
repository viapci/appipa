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

func makeDrops() -> [Drop] {
    var result: [Drop] = []
    let names = ["rain1", "rain2", "rain3"]
    for _ in 0..<8 {
        let drop = Drop(
            image: names[Int.random(in: 0..<names.count)],
            x: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 200...380),
            angle: Double.random(in: 0...360),
            spin: Double.random(in: -360...360),
            duration: Double.random(in: 7...14),
            delay: Double.random(in: 0...6)
        )
        result.append(drop)
    }
    return result
}
