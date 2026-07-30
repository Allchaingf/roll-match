//
//  Utilities.swift
//  RollMatch
//
//  Shared helpers: UIImagePickerController wrapper, image<->Data, PDF report builder,
//  and a UIActivityViewController share sheet.
//

import SwiftUI
import UIKit

// MARK: - Image picker (camera or library)

struct ImagePicker: UIViewControllerRepresentable {
    enum Source { case camera, library }
    var source: Source = .library
    var onPicked: (UIImage) -> Void
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if source == .camera, UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.onPicked(img)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

extension UIImage {
    /// Compress to a reasonable size for local storage.
    func rmData() -> Data? {
        let maxDim: CGFloat = 1100
        let scale = min(1, maxDim / max(size.width, size.height))
        if scale >= 1 { return jpegData(compressionQuality: 0.7) }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF report builder

enum PDFReport {
    static func build(for wall: Wall, units: MeasureUnit, currency: String,
                      sections: Set<String>) -> URL? {
        let pageW: CGFloat = 595   // A4 @72dpi
        let pageH: CGFloat = 842
        let bounds = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("RollMatch-\(wall.title.replacingOccurrences(of: " ", with: "_")).pdf")

        let r = MatchEngine.rollResult(for: wall)
        let center = MatchEngine.centerResult(for: wall)
        let plans = MatchEngine.stripPlans(for: wall)
        let cost = MatchEngine.totalCost(for: wall)

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y: CGFloat = 40
                let left: CGFloat = 40

                func line(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor, gap: CGFloat = 6) {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: size, weight: weight),
                        .foregroundColor: color
                    ]
                    let rect = CGRect(x: left, y: y, width: pageW - left * 2, height: size + 8)
                    (text as NSString).draw(in: rect, withAttributes: attrs)
                    y += size + gap
                }
                func divider() {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: left, y: y))
                    path.addLine(to: CGPoint(x: pageW - left, y: y))
                    UIColor(white: 0.8, alpha: 1).setStroke()
                    path.lineWidth = 0.6
                    path.stroke()
                    y += 12
                }
                func checkPage() {
                    if y > pageH - 70 { ctx.beginPage(); y = 40 }
                }

                // Header band
                UIColor(red: 0x0E/255, green: 0x1A/255, blue: 0x2E/255, alpha: 1).setFill()
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageW, height: 70)).fill()
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .heavy),
                    .foregroundColor: UIColor.white
                ]
                ("Roll Match — Hanging Plan" as NSString).draw(at: CGPoint(x: left, y: 22), withAttributes: titleAttrs)
                y = 86

                line(wall.title, size: 18, weight: .bold, color: .darkGray)
                line("Project: \(wall.projectName)   •   \(DateFormatter.rmMedium.string(from: wall.createdAt))",
                     size: 11, weight: .regular, color: .gray, gap: 12)
                divider()

                if sections.contains("Layout") {
                    line("WALL & PATTERN", size: 13, weight: .heavy, color: .black)
                    line("Size: \(MatchEngine.lengthString(wall.width, unit: units)) × \(MatchEngine.lengthString(wall.height, unit: units))", size: 11, weight: .regular, color: .darkGray)
                    line("Match: \(wall.pattern.matchType.label)   Repeat: \(MatchEngine.shortLength(wall.pattern.repeatHeight, unit: units))", size: 11, weight: .regular, color: .darkGray)
                    line("Roll: \(MatchEngine.shortLength(wall.roll.width, unit: units)) wide × \(MatchEngine.lengthString(wall.roll.length, unit: units)) long", size: 11, weight: .regular, color: .darkGray, gap: 12)
                    divider()
                }

                if sections.contains("Rolls") {
                    line("ROLL COUNT", size: 13, weight: .heavy, color: .black)
                    line("Strips needed: \(r.stripsNeeded)   Strips per roll: \(r.stripsPerRoll)", size: 11, weight: .regular, color: .darkGray)
                    line("Rolls (pattern): \(r.rollsForPattern)   Rolls (with \(Int(r.extraPercent))% extra): \(r.rollsTotal)", size: 11, weight: .bold, color: .black)
                    line(String(format: "Pattern waste: %.1f%%   Centering side cuts: %@ / %@",
                                r.patternWastePercent,
                                MatchEngine.shortLength(center.leftCut, unit: units),
                                MatchEngine.shortLength(center.rightCut, unit: units)),
                         size: 11, weight: .regular, color: .darkGray, gap: 12)
                    divider()
                }

                if sections.contains("Cut List") {
                    line("CUT LIST", size: 13, weight: .heavy, color: .black)
                    for p in plans {
                        checkPage()
                        line("Strip \(p.index): cut \(MatchEngine.lengthString(p.cutLength, unit: units))  •  shift \(MatchEngine.shortLength(p.repeatShift, unit: units))  •  trim \(MatchEngine.shortLength(p.trimTop, unit: units)) top / \(MatchEngine.shortLength(p.trimBottom, unit: units)) base",
                             size: 10.5, weight: p.isFirst ? .bold : .regular, color: p.isFirst ? .black : .darkGray, gap: 4)
                    }
                    y += 8; divider()
                }

                if sections.contains("Defects") && !wall.defects.isEmpty {
                    checkPage()
                    line("DEFECTS", size: 13, weight: .heavy, color: .black)
                    for d in wall.defects {
                        checkPage()
                        line("• \(d.type.label) (severity \(d.severity)/5) — \(d.fixAction.isEmpty ? "no action set" : d.fixAction)",
                             size: 10.5, weight: .regular, color: .darkGray, gap: 4)
                    }
                    y += 8; divider()
                }

                if sections.contains("Cost") {
                    checkPage()
                    line("COST", size: 13, weight: .heavy, color: .black)
                    line("Estimated total: \(currency)\(String(format: "%.2f", cost))", size: 12, weight: .bold, color: .black, gap: 12)
                    divider()
                }

                if sections.contains("Approval") {
                    checkPage()
                    line("APPROVAL", size: 13, weight: .heavy, color: .black)
                    line("Decision: \(wall.approval.decision.label)   Reviewer: \(wall.approval.reviewer.isEmpty ? "—" : wall.approval.reviewer)", size: 11, weight: .regular, color: .darkGray)
                    if !wall.approval.comment.isEmpty {
                        line("Comment: \(wall.approval.comment)", size: 11, weight: .regular, color: .darkGray)
                    }
                }
            }
            return url
        } catch {
            return nil
        }
    }
}

extension DateFormatter {
    static let rmMedium: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
    static let rmShortDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
}
