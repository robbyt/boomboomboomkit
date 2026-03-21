//
//  MelFilterbank.swift
//  BoomBoomBoomKit
//
//  Mel-scale conversion and triangular filterbank matrix
//

import Accelerate
import Foundation

/// Mel-scale conversion utilities and triangular filterbank construction.
///
/// Caseless enum namespace with static methods — pure functions on value types.
/// Only imports `Foundation` and `Accelerate`.
enum MelFilterbank {

  // MARK: - Mel-Scale Conversion

  /// Convert frequency in Hz to mel scale using O'Shaughnessy formula.
  static func hzToMel(_ hz: Double) -> Double {
    2595.0 * log10(1.0 + hz / 700.0)
  }

  /// Convert mel value back to Hz (inverse of `hzToMel`).
  static func melToHz(_ mel: Double) -> Double {
    700.0 * (pow(10.0, mel / 2595.0) - 1.0)
  }

  // MARK: - Filterbank Construction

  /// Build a triangular mel filterbank matrix.
  ///
  /// - Parameters:
  ///   - melBands: Number of mel bands (typically 128).
  ///   - fftSize: FFT size (e.g. 2048). Filterbank columns = fftSize/2.
  ///   - sampleRate: Audio sample rate in Hz.
  ///   - fmin: Minimum frequency in Hz (e.g. 30).
  ///   - fmax: Maximum frequency in Hz (e.g. 16000).
  /// - Returns: Flat row-major `[Float]` of size `melBands * (fftSize/2)`.
  static func buildFilterbank(
    melBands: Int,
    fftSize: Int,
    sampleRate: Double,
    fmin: Double,
    fmax: Double
  ) -> [Float] {
    let freqBins = fftSize / 2

    // Convert frequency bounds to mel scale
    let melMin = hzToMel(fmin)
    let melMax = hzToMel(fmax)

    // Create melBands + 2 equally spaced points in mel space
    let numPoints = melBands + 2
    var melPoints = [Double](repeating: 0, count: numPoints)
    let melStep = (melMax - melMin) / Double(numPoints - 1)
    for i in 0..<numPoints {
      melPoints[i] = melMin + Double(i) * melStep
    }

    // Convert mel points back to Hz, then to FFT bin indices
    var binIndices = [Int](repeating: 0, count: numPoints)
    for i in 0..<numPoints {
      let hz = melToHz(melPoints[i])
      binIndices[i] = Int(floor(Double(fftSize) * hz / sampleRate))
    }

    // Build triangular filters (row-major: melBands rows x freqBins cols)
    var filterbank = [Float](repeating: 0, count: melBands * freqBins)

    for m in 0..<melBands {
      let left = binIndices[m]
      let center = binIndices[m + 1]
      let right = binIndices[m + 2]

      // Rising slope: left to center
      if center > left {
        for k in left...min(center, freqBins - 1) {
          guard k >= 0, k < freqBins else { continue }
          filterbank[m * freqBins + k] = Float(k - left) / Float(center - left)
        }
      }

      // Falling slope: center to right
      if right > center {
        for k in center...min(right, freqBins - 1) {
          guard k >= 0, k < freqBins else { continue }
          filterbank[m * freqBins + k] = Float(right - k) / Float(right - center)
        }
      }

      // Slaney normalization: equal energy per Hz regardless of bandwidth
      if right > left {
        let norm = 2.0 / Float(right - left)
        for k in max(left, 0)..<min(right + 1, freqBins) {
          filterbank[m * freqBins + k] *= norm
        }
      }
    }

    return filterbank
  }
}
