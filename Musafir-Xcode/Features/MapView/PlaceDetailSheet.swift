//
//  PlaceDetailSheet.swift
//  Musafir-Xcode
//
//  Detail sheet from Design/Sheet.svg, presented when a prayer-space card is tapped.
//

import SwiftUI
import MapKit

struct PlaceDetailSheet: View {
    let item: MKMapItem
    let model: MapModel
    let religion: Religion

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                Button {
                    // Routed and drawn inside Musafir; handing off to Apple Maps
                    // would drop the user out of the app mid-journey.
                    model.startDirections(to: item)
                    model.isShowingDetail = false
                    dismiss()
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(MusafirTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(religion.placeholderName)
                        .font(.system(size: 18))

                    Text(model.addressText(for: item))
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                photoRow
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
    }

    /// Close button pinned to the leading edge with the place name centred over it.
    private var header: some View {
        ZStack {
            Text(item.name ?? religion.placeholderName)
                .font(.system(size: 20, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 56)

            HStack {
                Button {
                    model.isShowingDetail = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .frame(width: 48, height: 48)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.top, 12)
    }

    /// Three photo wells from the layout. MKMapItem carries no photos, so these stay
    /// placeholders until a photo source is wired up.
    private var photoRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.15))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                    )
            }
        }
    }
}
