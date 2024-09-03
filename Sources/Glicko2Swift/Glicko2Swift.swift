// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

public class Glicko2 {
    private let system_constant: Double
    private let e: Double

    public init(_ system_constant: Double = 0.5, _ e: Double = 0.000001) {
        self.system_constant = system_constant
        self.e = e
    }

    public func calculateRating(_ player: Player, matches: [(opponent: Player, result: GameResult)]) -> Player {
        // steps 3 and 4
        var varianceInv = 0.0
        var difference = 0.0
        for (opponent, result) in matches {
            let impact = reduceImpact(opponent)
            let expectedScore = expectScore(player: player, opponent: opponent, impact: impact)
            varianceInv += impact ** 2 * expectedScore * (1 - expectedScore)
            difference += impact * (result.rawValue - expectedScore)
        }
        difference /= varianceInv
        let variance = 1.0 / varianceInv
        // Step 5. Determine the new volatility
        let volatility = determineVolatility(player: player, difference: difference, variance: variance)

        // Step 6. Update the rating deviation to the new pre-rating period value, Phi*.
        let deviationStar = (player.glicko2Deviation ** 2 + volatility ** 2).squareRoot()

        // Step 7. Update the rating and RD to the new values, Mu' and Phi'.
        let deviation = 1.0 / (1 / deviationStar ** 2 + 1 / variance).squareRoot()
        let rating = player.glicko2Rating + deviation ** 2 * (difference / variance)

        var newPlayer = Player()
        newPlayer.glicko2Rating = rating
        newPlayer.glicko2Deviation = deviation
        newPlayer.glicko2Volatility = volatility

        return newPlayer

    }

    // The original form is `g(RD)`. This function reduces the impact of
    // games as a function of an opponent's RD.
    func reduceImpact(_ player: Player) -> Double {
        return 1.0 / (1 + (3 * player.glicko2Deviation ** 2) / (Double.pi ** 2)).squareRoot()
    }

    func expectScore(player: Player, opponent: Player, impact: Double) -> Double {
        return 1.0 / (1 + exp(-impact * (player.glicko2Rating - opponent.glicko2Rating)))
    }

    func determineVolatility(player: Player, difference: Double, variance: Double) -> Double {
        let deviation = player.glicko2Deviation
        let differenceSquared = difference ** 2
        // 1. Let a = ln(s^2), ad define f(x)
        let alpha = log(player.glicko2Volatility ** 2)

        func f(_ x: Double) -> Double {
            let tmp = deviation ** 2 + variance + exp(x)
            let a = exp(x) * (differenceSquared - tmp) / (2 * tmp ** 2)
            let b = (x - alpha) / (system_constant ** 2)
            return a - b
        }

        // 2. Set the initial values of the iterative algorithm.
        var a = alpha
        var b = 0.0
        if differenceSquared > deviation ** 2 + variance {
            b = log(differenceSquared - deviation ** 2 - variance)
        } else {
            var k = 1.0
            while f(alpha - k * (system_constant ** 2).squareRoot()) < 0 {
                k += 1.0
            }
            b = alpha - k * (system_constant ** 2).squareRoot()
        }

        // 3. let fA = f(a), fB=f(b)
        var fA = f(a), fB=f(b)

        // 4. While |B-A| > e, carry out the following steps.
        // (a) Let C = A + (A - B)fA / (fB-fA), and let fC = f(C).
        // (b) If fCfB < 0, then set A <- B and fA <- fB; otherwise, just set
        //     fA <- fA/2.
        // (c) Set B <- C and fB <- fC.
        // (d) Stop if |B-A| <= e. Repeat the above three steps otherwise.

        while abs(b - a) > e {
            let c = a + (a - b) * fA / (fB - fA)
            let fC = f(c)
            if fC * fB < 0 {
                a = b; fA = fB
            } else {
                fA /= 2
            }
            b = c; fB = fC
        }

        // 5. Once |B-A| <= e, set s' <- e^(A/2)
        return exp(1) ** (a / 2)
    }
}

public enum GameResult: Double {
    case win = 1.0
    case draw = 0.5
    case loss = 0.0
}

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence
func ** (radix: Double, power: Double) -> Double {
    return pow(radix, power)
}