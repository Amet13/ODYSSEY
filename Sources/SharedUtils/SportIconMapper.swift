import Foundation
import SwiftUI

/// Maps sport names to appropriate SF Symbols icons
/**
 SportIconMapper maps sport names to SF Symbol icon names for consistent UI representation.
 */
public enum SportIconMapper {
    // MARK: - Sport Icon Mappings

    /// Dictionary mapping sport keywords to SF Symbol icon names
    private static let sportIconMappings: [String: String] = [
        // MARK: - Swimming & Aqua Activities

        "swim": "figure.pool.swim",
        "lane swim": "figure.pool.swim",
        "aqua": "figure.pool.swim",
        "aquafit": "figure.pool.swim",
        "preschool swim": "figure.pool.swim",

        // MARK: - Basketball

        "basketball": "basketball.fill",
        "hoops": "basketball.fill",

        // MARK: - Volleyball

        "volleyball": "volleyball.fill",
        "volley": "volleyball.fill",

        // MARK: - Soccer

        "soccer": "soccerball",
        "football": "soccerball",

        // MARK: - Gym & Fitness Activities

        "open gym": "dumbbell.fill",
        "kindergym": "dumbbell.fill",
        "open turf": "sportscourt.fill",
        "rockwall": "figure.climbing",
        "rock wall": "figure.climbing",

        // MARK: - Fitness Classes

        "bootcamp": "figure.run",
        "cardio": "heart.fill",
        "hiit": "figure.run",
        "indoor cycling": "bicycle",
        "cycling": "bicycle",
        "trx": "dumbbell.fill",
        "core conditioning": "figure.mind.and.body",
        "core": "figure.mind.and.body",
        "strength": "dumbbell.fill",
        "step and strength": "figure.run",
        "stretch and strength": "figure.mind.and.body",
        "balance": "figure.mind.and.body",
        "stability": "figure.mind.and.body",
        "circuit": "dumbbell.fill",

        // MARK: - Dance & Movement

        "dance": "figure.dance",
        "zumba": "figure.dance",
        "drums alive": "figure.dance",
        "groove method": "figure.dance",
        "tmc": "figure.dance",

        // MARK: - Yoga & Mind-Body

        "yoga": "figure.mind.and.body",
        "pilates": "figure.mind.and.body",
        "yoga tune up": "figure.mind.and.body",

        // MARK: - Curling

        "curling": "curling.stone",

        // MARK: - Squash

        "squash": "squash.racket",

        // MARK: - Martial Arts

        "martial": "figure.martial.arts",
        "karate": "figure.martial.arts",
        "taekwondo": "figure.martial.arts",

        // MARK: - Climbing

        "climbing": "figure.climbing",
        "climb": "figure.climbing",

        // MARK: - Skating

        "skating": "figure.skating",
        "skate": "figure.skating",

        // MARK: - Skiing

        "skiing": "figure.skiing.downhill",
        "ski": "figure.skiing.downhill",

        // MARK: - Baseball

        "baseball": "baseball.fill",
        "softball": "baseball.fill",

        // MARK: - Cricket

        "cricket": "cricket.bat",

        // MARK: - Table Tennis

        "table tennis": "table.tennis",
        "ping pong": "table.tennis",
        "pingpong": "table.tennis",

        // MARK: - Racquetball

        "racquetball": "racquetball.racket",

        // MARK: - American Football

        "american football": "football.fill",

        // MARK: - Boxing

        "boxing": "figure.boxing",
        "box": "figure.boxing",

        // MARK: - Ice Hockey

        "ice hockey": "hockey.puck",
        "icehockey": "hockey.puck",

        // MARK: - Rock Climbing

        "rock climbing": "figure.climbing",
        "rockclimbing": "figure.climbing",

        // MARK: - Meditation

        "meditation": "figure.mind.and.body",
        "meditate": "figure.mind.and.body",
    ]

    /// Returns the appropriate SF Symbol icon name for a given sport
    /// - Parameter sportName: The name of the sport
    /// - Returns: SF Symbol icon name
    public static func iconForSport(_ sportName: String) -> String {
        let lowercasedSport = sportName.lowercased()

        // Check for exact matches first (longer phrases)
        for (keyword, icon) in sportIconMappings where lowercasedSport.contains(keyword) {
            return icon
        }

        // Default fallback for any sport not specifically mapped
        return "sportscourt.fill"
    }
}

/// A SwiftUI view that displays a sport icon with fallback if the symbol is unavailable
/**
 SportIconView displays a SwiftUI icon for a given sport, with fallback and color options.
 */
public struct SportIconView: View {
    public let symbolName: String
    public let fallback: String
    public let color: Color
    public let size: CGFloat

    public init(
        symbolName: String,
        fallback: String = "sportscourt.fill",
        color: Color = .accentColor,
        size: CGFloat = 16
    ) {
        self.symbolName = symbolName
        self.fallback = fallback
        self.color = color
        self.size = size
    }

    public var body: some View {
        #if os(macOS)
        if NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil {
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallback)
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: size, height: size)
        }
        #else
        if UIImage(systemName: symbolName) != nil {
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallback)
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: size, height: size)
        }
        #endif
    }
}
