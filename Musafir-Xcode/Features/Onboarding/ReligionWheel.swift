//
//  ReligionWheel.swift
//  Musafir-Xcode
//
//  Drag-to-scroll wheel with the row metrics from "Nomaden Onboarding 5".
//  The system wheel picker fixes its own row height, so it can't match them.
//

import SwiftUI

struct ReligionWheel: View {
    @Binding var selection: Religion

    /// Baseline-to-baseline distance between two unselected rows.
    private let rowPitch: CGFloat = 39
    /// Extra space either side of the selected row (46pt to its neighbours).
    private let selectedGap: CGFloat = 7
    private let selectedFontSize: CGFloat = 35
    private let unselectedFontSize: CGFloat = 26
    /// The selected row sits slightly below the card's middle in the mockup.
    private let centerOffset: CGFloat = 6

    private let options = Religion.allCases

    /// Fractional index of the row under the centre line. Follows the finger while dragging.
    @State private var position: CGFloat = 0
    @State private var dragStart: CGFloat?

    var body: some View {
        GeometryReader { proxy in
            let midY = proxy.size.height / 2 + centerOffset
            ZStack {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    row(option, distance: CGFloat(index) - position)
                        .position(x: proxy.size.width / 2, y: midY + yOffset(CGFloat(index) - position))
                        .onTapGesture { select(index) }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .mask(fadeMask)
        .onAppear { position = CGFloat(index(of: selection)) }
        .onChange(of: selection) { _, newValue in
            guard dragStart == nil else { return }
            withAnimation(.snappy) { position = CGFloat(index(of: newValue)) }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement()
        .accessibilityLabel("Religion")
        .accessibilityValue(selection.displayName)
        .accessibilityAdjustableAction { direction in
            let current = index(of: selection)
            switch direction {
            case .increment: select(current + 1)
            case .decrement: select(current - 1)
            @unknown default: break
            }
        }
    }

    // MARK: - Layout

    private func row(_ option: Religion, distance: CGFloat) -> some View {
        // 0 on the centre line, 1 once a full row away.
        let t = min(abs(distance), 1)
        return Text(option.displayName)
            .font(.system(size: selectedFontSize, weight: .medium))
            // Selected row is white at 85%; neighbours keep the opaque gray.
            .foregroundStyle(Color(white: 1 - 0.4 * t).opacity(0.85 + 0.15 * t))
            .scaleEffect(1 - (1 - unselectedFontSize / selectedFontSize) * t)
            .fixedSize(horizontal: true, vertical: true)
    }

    /// Rows are `rowPitch` apart, pushed out by `selectedGap` next to the centre row.
    private func yOffset(_ distance: CGFloat) -> CGFloat {
        rowPitch * distance + selectedGap * max(-1, min(1, distance))
    }

    /// Transparent at the top and bottom edges, solid across the middle rows.
    private var fadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.03),
                .init(color: .black, location: 0.37),
                .init(color: .black, location: 0.63),
                .init(color: .clear, location: 0.97),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Interaction

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let start = dragStart ?? position
                dragStart = start
                position = rubberBand(start - value.translation.height / rowPitch)
                let nearest = clampedIndex(Int(position.rounded()))
                if options[nearest] != selection { selection = options[nearest] }
            }
            .onEnded { value in
                let start = dragStart ?? position
                dragStart = nil
                let projected = start - value.predictedEndTranslation.height / rowPitch
                select(Int(projected.rounded()))
            }
    }

    private func select(_ index: Int) {
        let target = clampedIndex(index)
        withAnimation(.snappy) { position = CGFloat(target) }
        selection = options[target]
    }

    /// Lets the wheel stretch a little past the first and last rows.
    private func rubberBand(_ value: CGFloat) -> CGFloat {
        let upper = CGFloat(options.count - 1)
        if value < 0 { return value / 3 }
        if value > upper { return upper + (value - upper) / 3 }
        return value
    }

    private func clampedIndex(_ index: Int) -> Int {
        max(0, min(options.count - 1, index))
    }

    private func index(of religion: Religion) -> Int {
        options.firstIndex(of: religion) ?? 0
    }
}

#Preview {
    @Previewable @State var religion: Religion = .katolik
    ReligionWheel(selection: $religion)
        .frame(width: 307, height: 285)
        .background(.purple)
}
