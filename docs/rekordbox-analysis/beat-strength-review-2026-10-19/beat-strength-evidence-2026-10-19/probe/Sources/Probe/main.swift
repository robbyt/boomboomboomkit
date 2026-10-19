import Foundation
func check(_ name: String, _ b: [Float]) {
 let o = FramewiseObservations(frameRate:100, firstFrameOriginSeconds:0, coverageWindowSeconds:Double(b.count)/100, beatProbabilities:b, downbeatProbabilities:b.map{$0*0.5}, modelIdentifier:"review", frontendIdentifier:"synthetic")
 let d = BarStateDecoder.decode(observations:o,tempoBPM:120,level:.quarter)
 let sel = MetricalLevelSelector.select(observations:o,tempoBPM:120)
 let fit = sel.flatMap{JointTempoPhaseFit.fit(observations:o,selection:$0)}
 let row: [String:Any] = ["name":name,"frames":d?.beats.map{Int(($0.time*100).rounded())} ?? [],"gridIndices":d?.beats.map{$0.gridIndex} ?? [],"contrast":d?.contrastScore ?? -999,"chosenLevel":sel?.chosen.metricalLevel.rawValue ?? "nil","fitBPM":fit?.tempoBPM ?? 0,"fitAnchor":fit?.phaseAnchorSeconds ?? -1]
 print(String(data:try! JSONSerialization.data(withJSONObject:row,options:[.sortedKeys]),encoding:.utf8)!)
}
check("constant-low",Array(repeating:Float(0.01),count:400))
check("constant-high",Array(repeating:Float(0.5),count:1200))
var b=Array(repeating:Float(0.01),count:400)
for i in [10,60,110,260,310] {b[i]=1}
check("gap-positive-floor",b)
var zero=Array(repeating:Float(0),count:400)
for i in [10,60,110,260,310] {zero[i]=1}
check("gap-zero-floor",zero)
