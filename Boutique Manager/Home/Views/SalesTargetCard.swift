import SwiftUI
struct SalesTargetCard: View {
    let totalAchieved: Double
    let targetAmount: Double
    let location: String
    let flag: String
    
    private var percentage: Int {
        if targetAmount > 0 {
            return Int((totalAchieved / targetAmount) * 100)
        }
        return 0
    }
    
    private var statusColor: Color {
        // ALWAYS use .themeAccent for the premium boutique look rather than generic green
        .themeAccent
    }
    
    private var statusText: String {
        percentage >= 100 ? "Goal Exceeded" : "In Progress"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header
            HStack {
                Label("\(location) \(flag)", systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.bottom, 20)
            
            HStack(alignment: .center) {
                // Left: Monetary Figures
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Revenue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .tracking(1.5) // Elegant tracking
                        .textCase(.uppercase)
                    
                    Text(formatSales(totalAchieved))
                        .font(.system(size: 38, weight: .regular, design: .serif)) // Luxury serif typography
                        .foregroundStyle(Color.themeText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Target: \(formatSales(targetAmount))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Status Pill
                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.themeText)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.themeAccent.opacity(0.15))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Right: Circular Progress with Percentage inside
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 8) // Elegant thin ring
                    
                    // Progress fill
                    Circle()
                        .trim(from: 0, to: CGFloat(min(percentage, 100)) / 100.0)
                        .stroke(
                            LinearGradient(
                                colors: [statusColor.opacity(0.5), statusColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round) // Elegant thin ring
                        )
                        .rotationEffect(.degrees(-90))
                    
                    // Center Text
                    VStack(spacing: 0) {
                        Text("\(percentage)%")
                            .font(.system(size: 26, weight: .regular, design: .serif)) // Luxury serif typography
                            .foregroundStyle(Color.themeText)
                        
                        Text("Achieved")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .tracking(1.0)
                            .textCase(.uppercase)
                    }
                }
                .frame(width: 100, height: 100)
                .padding(.trailing, 10)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .padding(20)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
    
    private func formatSales(_ amount: Double) -> String {
        // Formatter to handle large values elegantly (e.g. 10.5M, 150k)
        if amount >= 1_000_000 {
            return String(format: "$%.1fM", amount / 1_000_000.0)
        } else if amount >= 1_000 {
            return String(format: "$%.1fk", amount / 1_000.0)
        } else {
            return String(format: "$%.0f", amount)
        }
    }
}
#Preview {
    SalesTargetCard(totalAchieved: 10965000, targetAmount: 8500000, location: "Cupertino, CA", flag: "🇺🇸")
        .padding()
        .background(Color.themeBackground)
}
