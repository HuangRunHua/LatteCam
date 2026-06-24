import SwiftUI
import UIKit

struct EnergySaverOverlay: View {
    @Binding var isPresented: Bool
    @State private var previousBrightness: CGFloat?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Text("LatteCam 仍在前台运行")
                    .font(.footnote)

                Text("双击退出节能模式")
                    .font(.caption)
            }
            .foregroundStyle(Color(white: 0.18))
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            restoreBrightness()
            isPresented = false
        }
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 0.0
        }
        .onDisappear {
            restoreBrightness()
        }
    }

    private func restoreBrightness() {
        if let previousBrightness {
            UIScreen.main.brightness = previousBrightness
        }
    }
}
