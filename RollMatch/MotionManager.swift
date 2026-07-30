//
//  MotionManager.swift
//  RollMatch
//
//  Lightweight CoreMotion wrapper for the onboarding gyroscope parallax.
//

import Foundation
import CoreMotion
import Combine

final class MotionManager: ObservableObject {
    @Published var roll: Double = 0   // left/right tilt
    @Published var pitch: Double = 0  // forward/back tilt
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let m = motion else { return }
            // clamp for gentle parallax
            self.roll = max(-0.6, min(0.6, m.attitude.roll))
            self.pitch = max(-0.6, min(0.6, m.attitude.pitch))
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        roll = 0
        pitch = 0
    }
}
