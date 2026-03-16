import SwiftUI

struct SpeedGaugeView: View {
    let value: Double
    let maxValue: Double
    let label: String
    let color: Color

    private var percentage: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Background arc
                ArcShape(progress: 1.0)
                    .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 110, height: 58)

                // Value arc
                ArcShape(progress: percentage)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 110, height: 58)
                    .animation(.easeOut(duration: 0.5), value: percentage)

                VStack(spacing: 0) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    Text("Mbps")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .offset(y: 6)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct ArcShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 180 + (180 * progress))

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
