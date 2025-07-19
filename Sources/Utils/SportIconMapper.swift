import Foundation
import SwiftUI

/// Maps sport names to appropriate SF Symbols icons
enum SportIconMapper {
    /// Returns the appropriate SF Symbol icon name for a given sport
    /// - Parameter sportName: The name of the sport
    /// - Returns: SF Symbol icon name
    static func iconForSport(_ sportName: String) -> String {
        let lowercasedSport = sportName.lowercased()

        // MARK: - Swimming & Aqua Activities

        // Swimming variations
        if lowercasedSport.contains("swim") || lowercasedSport.contains("lane swim") {
            return "figure.pool.swim"
        }

        // Aqua activities (including variations)
        if lowercasedSport.contains("aqua") || lowercasedSport.contains("aquafit") {
            return "figure.pool.swim"
        }

        // Preschool swim
        if lowercasedSport.contains("preschool swim") {
            return "figure.pool.swim"
        }

        // MARK: - Basketball

        // Basketball variations (including age-specific)
        if lowercasedSport.contains("basketball") || lowercasedSport.contains("hoops") {
            return "basketball.fill"
        }

        // MARK: - Volleyball

        // Volleyball variations (including age-specific)
        if lowercasedSport.contains("volleyball") || lowercasedSport.contains("volley") {
            return "volleyball.fill"
        }

        // MARK: - Soccer

        // Soccer variations (including age-specific)
        if lowercasedSport.contains("soccer") || lowercasedSport.contains("football") {
            return "soccerball"
        }

        // MARK: - Gym & Fitness Activities

        // Open gym variations
        if lowercasedSport.contains("open gym") || lowercasedSport.contains("kindergym") {
            return "dumbbell.fill"
        }

        // Open turf
        if lowercasedSport.contains("open turf") {
            return "sportscourt.fill"
        }

        // Rockwall
        if lowercasedSport.contains("rockwall") || lowercasedSport.contains("rock wall") {
            return "figure.climbing"
        }

        // MARK: - Fitness Classes

        // Bootcamp variations
        if lowercasedSport.contains("bootcamp") {
            return "figure.run"
        }

        // Cardio variations (including older adult versions)
        if lowercasedSport.contains("cardio") {
            return "heart.fill"
        }

        // HIIT
        if lowercasedSport.contains("hiit") {
            return "figure.run"
        }

        // Indoor cycling
        if lowercasedSport.contains("indoor cycling") || lowercasedSport.contains("cycling") {
            return "bicycle"
        }

        // TRX
        if lowercasedSport.contains("trx") {
            return "dumbbell.fill"
        }

        // Core conditioning variations
        if lowercasedSport.contains("core conditioning") || lowercasedSport.contains("core") {
            return "figure.mind.and.body"
        }

        // Strength variations (including older adult versions)
        if lowercasedSport.contains("strength") {
            return "dumbbell.fill"
        }

        // Step and strength
        if lowercasedSport.contains("step and strength") {
            return "figure.run"
        }

        // Stretch and strength
        if lowercasedSport.contains("stretch and strength") {
            return "figure.mind.and.body"
        }

        // Balance and stability
        if lowercasedSport.contains("balance") || lowercasedSport.contains("stability") {
            return "figure.mind.and.body"
        }

        // Circuit training
        if lowercasedSport.contains("circuit") {
            return "dumbbell.fill"
        }

        // MARK: - Dance & Movement

        // Dance
        if lowercasedSport.contains("dance") {
            return "figure.dance"
        }

        // Zumba variations (including toning and older adult versions)
        if lowercasedSport.contains("zumba") {
            return "figure.dance"
        }

        // Drums Alive
        if lowercasedSport.contains("drums alive") {
            return "figure.dance"
        }

        // The Groove Method
        if lowercasedSport.contains("groove method") {
            return "figure.dance"
        }

        // TMC variations (including older adult versions)
        if lowercasedSport.contains("tmc") {
            return "figure.dance"
        }

        // MARK: - Yoga & Mind-Body

        // Yoga variations
        if lowercasedSport.contains("yoga") {
            return "figure.mind.and.body"
        }

        // Pilates
        if lowercasedSport.contains("pilates") {
            return "figure.mind.and.body"
        }

        // Yoga Tune Up
        if lowercasedSport.contains("yoga tune up") {
            return "figure.mind.and.body"
        }

        // MARK: - Curling

        // Curling variations (including sheet-specific and age-specific)
        if lowercasedSport.contains("curling") {
            return "curling.stone"
        }

        // MARK: - Squash

        // Squash variations (including court-specific)
        if lowercasedSport.contains("squash") {
            return "squash.racket"
        }

        // MARK: - Legacy Sports (keeping existing mappings)

        // Tennis and Badminton and Pickleball
        if
            lowercasedSport.contains("tennis") || lowercasedSport.contains("badminton") || lowercasedSport
                .contains("pickleball") {
            return "tennis.racket"
        }

        // Hockey
        if lowercasedSport.contains("hockey") {
            return "hockey.puck"
        }

        // Running
        if lowercasedSport.contains("running") || lowercasedSport.contains("run") {
            return "figure.run"
        }

        // Martial Arts
        if
            lowercasedSport.contains("martial") || lowercasedSport.contains("karate") || lowercasedSport
                .contains("taekwondo") {
            return "figure.martial.arts"
        }

        // Climbing
        if lowercasedSport.contains("climbing") || lowercasedSport.contains("climb") {
            return "figure.climbing"
        }

        // Skating
        if lowercasedSport.contains("skating") || lowercasedSport.contains("skate") {
            return "figure.skating"
        }

        // Skiing
        if lowercasedSport.contains("skiing") || lowercasedSport.contains("ski") {
            return "figure.skiing.downhill"
        }

        // Baseball
        if lowercasedSport.contains("baseball") {
            return "baseball.fill"
        }

        // Softball
        if lowercasedSport.contains("softball") {
            return "baseball.fill"
        }

        // Cricket
        if lowercasedSport.contains("cricket") {
            return "cricket.bat"
        }

        // Table Tennis/Ping Pong
        if
            lowercasedSport.contains("table tennis") || lowercasedSport.contains("ping pong") || lowercasedSport
                .contains("pingpong") {
            return "table.tennis"
        }

        // Squash
        if lowercasedSport.contains("squash") {
            return "squash.racket"
        }

        // Racquetball
        if lowercasedSport.contains("racquetball") {
            return "racquetball.racket"
        }

        // American Football
        if lowercasedSport.contains("american football") || lowercasedSport.contains("football") {
            return "football.fill"
        }

        // Boxing
        if lowercasedSport.contains("boxing") || lowercasedSport.contains("box") {
            return "figure.boxing"
        }

        // Ice Hockey
        if lowercasedSport.contains("ice hockey") || lowercasedSport.contains("icehockey") {
            return "hockey.puck"
        }

        // Rock Climbing
        if lowercasedSport.contains("rock climbing") || lowercasedSport.contains("rockclimbing") {
            return "figure.climbing"
        }

        // Meditation
        if lowercasedSport.contains("meditation") || lowercasedSport.contains("meditate") {
            return "figure.mind.and.body"
        }

        // Default fallback for any sport not specifically mapped
        return "sportscourt.fill"
    }
}

/// A SwiftUI view that displays a sport icon with fallback if the symbol is unavailable
struct SportIconView: View {
    let symbolName: String
    let fallback: String
    let color: Color
    let size: CGFloat

    init(symbolName: String, fallback: String = "sportscourt.fill", color: Color = .accentColor, size: CGFloat = 16) {
        self.symbolName = symbolName
        self.fallback = fallback
        self.color = color
        self.size = size
    }

    var body: some View {
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
