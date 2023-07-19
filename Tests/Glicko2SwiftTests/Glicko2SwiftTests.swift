import XCTest
import SwiftCSV
@testable import Glicko2Swift

final class Glicko2SwiftTests: XCTestCase {
    func testPaperExample() throws {
        var player = Player(rating: 1500, deviation: 200, volatility: 0.06)
        let opponents = [Player(rating: 1400, deviation: 30, volatility: 0.06),
                                   Player(rating: 1550, deviation: 100, volatility: 0.06),
                                   Player(rating: 1700, deviation: 300, volatility: 0.06)]
        player = Glicko2(0.5).calculateRating(player, matches: [(opponents[0], GameResult.win),(opponents[1], GameResult.loss),(opponents[2], GameResult.loss)])
        XCTAssertEqual(player.rating, 1464.05)
        XCTAssertEqual(player.deviation, 151.52)
        XCTAssertEqual(player.volatility, 0.05999, accuracy: 1e5)
    }

    func testCCALeauge() throws {
        var teams = [String: Player]()
        var histData = [String:[(power: Double, powerDelta: Double, gamePowerDelta: [Double])]]()
        let csv = try! CSV<Enumerated>(url: URL(fileURLWithPath: "CCAResults.csv"))
        let weeks = csv.columns![1..<csv.columns!.endIndex]
            .split(whereSeparator: { $0.rows.allSatisfy({ Int($0) != nil })})
            .filter({ !$0.isEmpty })
            .map({ $0.map({ $0.rows })})
        for (j, week) in weeks.enumerated() {
            print("Week \(j + 1)")
            for i in 0..<week[0].count {
                var teamAlpha = teams[week[1][i], default: Player()]
                var teamBeta = teams[week[2][i], default: Player()]

                let games = Array(week[0][i]).map({ result in
                    switch result {
                        case "W": return GameResult.win
                        case "L": return GameResult.loss
                        default: return GameResult.win
                    }
                })
                let glicko = Glicko2(0.5)
                var alphaScoreDiffs = [Double]()
                var betaScoreDiffs = [Double]()
                for game in games {
                    let tmpAlpha = teamAlpha
                    let tmpBeta = teamBeta
                    teamAlpha = glicko.calculateRating(teamAlpha, matches: [(teamBeta, game)])
                    teamBeta = glicko.calculateRating(teamBeta, matches: [(tmpAlpha, (game == .win ? .loss : .win))])
                    alphaScoreDiffs.append(round((teamAlpha.rating - tmpAlpha.rating) * 1e2) / 1e2)
                    betaScoreDiffs.append(round((teamBeta.rating - tmpBeta.rating) * 1e2) / 1e2)
                }
                histData[week[1][i], default: [(Double, Double, [Double])]()].append((teams[week[1][i], default: Player()].rating, round((teamAlpha.rating - teams[week[1][i], default: Player()].rating) * 1e2) / 1e2, alphaScoreDiffs))
                histData[week[2][i], default: [(Double, Double, [Double])]()].append((teams[week[2][i], default: Player()].rating, round((teamBeta.rating - teams[week[1][i], default: Player()].rating) * 1e2) / 1e2, betaScoreDiffs))
                teams[week[1][i]] = teamAlpha
                teams[week[2][i]] = teamBeta
            }
        }
        var newCSV = "Rank,Team,Final power,"
        for i in (1...weeks.count).reversed() {
            newCSV.append("Power at start of Week \(i),Change in power,")
            for j in (1...7) {
                newCSV.append("Change in game \(j),")
            }
        }
        newCSV += "\n"


        var count = 1
        let data = histData.reduce(into: [(name: String, power: Double, histData: [(power: Double, powerDelta: Double, gamePowerDelta: [Double])])](), { $0.append(($1.key, teams[$1.key]!.rating, $1.value))})
        for (name, power, history) in data.sorted(by: { $0.power > $1.power }) {
            newCSV.append("\(count),\"\(name)\",\"\(power)\",")
            for (power, powerDelta, gamePowerDelta) in history.reversed() {
                newCSV.append("\"\(power)\",\"")
                if powerDelta > 0 {
                    newCSV.append("+")
                }
                newCSV.append("\(powerDelta)\",")
                for delta in gamePowerDelta {
                    newCSV.append("\"")
                    if delta > 0 {
                        newCSV.append("+")
                    }
                    newCSV.append("\(delta)\",")
                }
                for _ in gamePowerDelta.count..<7 {
                    newCSV.append(",")
                }
            }
            newCSV.append("\n")
            count += 1
        }

        try! newCSV.write(toFile: "newCSV.csv", atomically: true, encoding: .utf8)
    }
}
