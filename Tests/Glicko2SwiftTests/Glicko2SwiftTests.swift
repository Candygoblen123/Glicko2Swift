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
        let csv = try! CSV<Enumerated>(url: URL(fileURLWithPath: "CCAResults.csv"))
        let weeks = csv.columns![1..<csv.columns!.endIndex]
            .split(whereSeparator: { $0.rows.allSatisfy({ Int($0) != nil })})
            .filter({ !$0.isEmpty })
            .map({ $0.map({ $0.rows })})
        for week in weeks {
            for i in 0..<week[0].count {
                var matches = [(Player, GameResult)]()
                var invMatches = [(Player, GameResult)]()
                let teamAlpha = teams[week[1][i], default: Player()]
                let teamBeta = teams[week[2][i], default: Player()]

                let games = week[0][i].split(separator: "-").map({Int($0)!})
                var flag = true
                for game in games {
                    for _ in 0..<game {
                        if flag {
                            matches.append((teamBeta, GameResult.win))
                            invMatches.append((teamAlpha, GameResult.loss))
                        } else {
                            matches.append((teamBeta, GameResult.loss))
                            invMatches.append((teamAlpha, GameResult.win))
                        }
                    }
                    flag.toggle()
                }

                let glicko = Glicko2(0.5)

                teams[week[1][i]] = glicko.calculateRating(teamAlpha, matches: matches)
                teams[week[2][i]] = glicko.calculateRating(teamBeta, matches: invMatches)
            }
            //print(teams["Splatlanders"]!.rating)
        }
        let powers = teams.reduce(into: [String:Double](), { $0[$1.key] = $1.value.rating })
        var count = 1
        for (name, power) in powers.sorted(by: { $0.value > $1.value }) {
            print("\(count): \(name) : \(power)")
            count += 1
        }
    }
}
