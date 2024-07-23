import Foundation

// Values are automatically converted to and from Glicko 1 scale (Step 2/step 8)
public struct Player {
    internal var glicko2Rating: Double = 0.0
    public var rating: Double {
        get {
            return round(((self.glicko2Rating * 173.7178) + 1500) * 1e2) / 1e2
        }
        set(r) {
            self.glicko2Rating =  (r - 1500)/173.7178
        }
    }
    internal var glicko2Deviation: Double = 0.0
    public var deviation: Double {
        get {
            return round((self.glicko2Deviation * 173.7178) * 1e2) / 1e2
        }
        set(d) {
            self.glicko2Deviation = d/173.7178
        }
    }
    internal var glicko2Volatility: Double = 0.0
    public var volatility: Double {
        get {
            return glicko2Volatility
        }
        set(v) {
            self.glicko2Volatility = v
        }
    }

    // Defaults are based off of Splatoon 2's internal Regular battle and Splatfest battle initial values. 
    // https://splatoonwiki.org/wiki/Power_level#Regular_and_Splatfest_Battles
    public init(rating: Double = 1600, deviation: Double = 250, volatility: Double = 0.6) {
        self.rating = rating
        self.deviation = deviation
        self.volatility = volatility
    }
}