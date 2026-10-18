import Foundation
import Testing
@testable import BoomBoomBoomKit
struct TimingProbeTests {
 @Test func absoluteClickPhase() throws {
  for sr in [44100.0, 48000.0] {
   let hop = Int(sr / 100), beatSamples = Int(sr / 2)
   for offset in [0, hop/2, hop-1] {
    for decay in [false,true] {
     var samples = [Float](repeating: 0, count: Int(sr*12))
     for p in stride(from: beatSamples+offset, to: samples.count-64, by: beatSamples) {
      for j in 0..<(decay ? 64 : 1) { samples[p+j] = Float(exp(-Double(j)/10)) }
     }
     let decoded = FeatureSubstrate.DecodedAudio(samples:samples, sampleRate:sr, codecPriming:.init(codec:.linearPCM,trimState:.knownNone))
     let env = BPMAnalyzer.computeMelOnsetEnvelope(samples:samples,sampleRate:sr,hopSize:hop)
     let isolated = try #require(BeatGridAnalyzer.estimateBeatGrid(onsetEnvelope:env,onsetRate:sr/Double(hop),hopSize:hop,sampleRate:sr,acf:env,tempoBPM:120,windowStartSample:0))
     var options = AudioAnalysisService.Options(); options.intensity = .level3
     let facadeResult = try AudioAnalysisService.analyzeBeatGrid(decoded:decoded,options:options)
     let facade = try #require(facadeResult)
     for (path,grid) in [("known-tempo",isolated),("public-facade",facade)] {
      let residuals = grid.beats.filter{$0.presentationTime > 1 && $0.presentationTime < 11}.map { beat -> Double in
       let phase = (beat.presentationTime - Double(offset)/sr)/0.5
       return (phase-phase.rounded())*0.5*1000
      }.sorted()
      let median=residuals[residuals.count/2]
      let anchorPhase = ((grid.gridOrigin!.presentationTime - Double(offset)/sr)/0.5)
      let anchorError = (anchorPhase-anchorPhase.rounded())*0.5*1000
      let row:[String:Any] = ["anchorSignedErrorMs":anchorError,"path":path,"sampleRate":sr,"offsetSamples":offset,"waveform":decay ? "64-sample-exp-decay":"single-impulse","bpm":grid.estimatedTempo,"gridConfidence":grid.confidence,"beatCount":grid.beats.count,"interiorCount":residuals.count,"medianSignedErrorMs":median,"minSignedErrorMs":residuals.first!,"maxSignedErrorMs":residuals.last!,"meanBeatConfidence":grid.beats.reduce(0){$0+Double($1.confidence)}/Double(grid.beats.count)]
      print("TIMING_PROBE "+String(data:try JSONSerialization.data(withJSONObject:row,options:[.sortedKeys]),encoding:.utf8)!)
     }
    }
   }
  }
 }
}
