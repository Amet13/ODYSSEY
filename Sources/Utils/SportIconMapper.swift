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

        // MARK: - Badminton

        // Badminton variations (including age-specific)
        if lowercasedSport.contains("badminton") {
            return "badminton.racket"
        }

        // MARK: - Soccer

        // Soccer variations (including age-specific)
        if lowercasedSport.contains("soccer") || lowercasedSport.contains("football") {
            return "soccerball"
        }

        // MARK: - Pickleball

        // Pickleball variations (including age and skill levels)
        if lowercasedSport.contains("pickleball") {
            return "pickleball.racket"
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

        // MARK: - Age-Specific Activities

        // 50+ activities
        if lowercasedSport.contains("50+") || lowercasedSport.contains("older adult") {
            return "figure.mind.and.body"
        }

        // Family activities
        if lowercasedSport.contains("family") {
            return "figure.2.and.child.holdinghands"
        }

        // Youth activities
        if lowercasedSport.contains("youth") {
            return "figure.2.and.child.holdinghands"
        }

        // Adult activities
        if lowercasedSport.contains("adult") {
            return "person.fill"
        }

        // All ages activities
        if lowercasedSport.contains("all ages") {
            return "person.3.fill"
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

        // Tennis
        if lowercasedSport.contains("tennis") {
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

        // Handball
        if lowercasedSport.contains("handball") {
            return "handball"
        }

        // Rugby
        if lowercasedSport.contains("rugby") {
            return "rugby.ball"
        }

        // American Football
        if lowercasedSport.contains("american football") || lowercasedSport.contains("football") {
            return "football.fill"
        }

        // Lacrosse
        if lowercasedSport.contains("lacrosse") {
            return "lacrosse.stick"
        }

        // Curling
        if lowercasedSport.contains("curling") {
            return "curling.stone"
        }

        // Bowling
        if lowercasedSport.contains("bowling") {
            return "bowling.ball"
        }

        // Golf
        if lowercasedSport.contains("golf") {
            return "golf.club"
        }

        // Archery
        if lowercasedSport.contains("archery") {
            return "bow.and.arrow"
        }

        // Fencing
        if lowercasedSport.contains("fencing") {
            return "fencing.sword"
        }

        // Boxing
        if lowercasedSport.contains("boxing") || lowercasedSport.contains("box") {
            return "figure.boxing"
        }

        // Wrestling
        if lowercasedSport.contains("wrestling") || lowercasedSport.contains("wrestle") {
            return "figure.wrestling"
        }

        // Gymnastics
        if lowercasedSport.contains("gymnastics") || lowercasedSport.contains("gymnastic") {
            return "figure.gymnastics"
        }

        // Track and Field
        if
            lowercasedSport.contains("track") || lowercasedSport.contains("field") || lowercasedSport
                .contains("athletics") {
            return "figure.track.and.field"
        }

        // Cross Country
        if lowercasedSport.contains("cross country") || lowercasedSport.contains("crosscountry") {
            return "figure.cross.country"
        }

        // Triathlon
        if lowercasedSport.contains("triathlon") {
            return "figure.triathlon"
        }

        // Water Polo
        if lowercasedSport.contains("water polo") || lowercasedSport.contains("waterpolo") {
            return "water.polo"
        }

        // Synchronized Swimming
        if lowercasedSport.contains("synchronized swimming") || lowercasedSport.contains("synchro") {
            return "figure.synchronized.swimming"
        }

        // Diving
        if lowercasedSport.contains("diving") || lowercasedSport.contains("dive") {
            return "figure.diving"
        }

        // Canoe/Kayak
        if lowercasedSport.contains("canoe") || lowercasedSport.contains("kayak") {
            return "canoe"
        }

        // Rowing
        if lowercasedSport.contains("rowing") || lowercasedSport.contains("row") {
            return "rowing"
        }

        // Sailing
        if lowercasedSport.contains("sailing") || lowercasedSport.contains("sail") {
            return "sailboat"
        }

        // Surfing
        if lowercasedSport.contains("surfing") || lowercasedSport.contains("surf") {
            return "surfboard"
        }

        // Snowboarding
        if lowercasedSport.contains("snowboarding") || lowercasedSport.contains("snowboard") {
            return "snowboard"
        }

        // Ice Hockey
        if lowercasedSport.contains("ice hockey") || lowercasedSport.contains("icehockey") {
            return "hockey.puck"
        }

        // Field Hockey
        if lowercasedSport.contains("field hockey") || lowercasedSport.contains("fieldhockey") {
            return "field.hockey.stick"
        }

        // Ultimate Frisbee
        if lowercasedSport.contains("ultimate") || lowercasedSport.contains("frisbee") {
            return "frisbee"
        }

        // Disc Golf
        if lowercasedSport.contains("disc golf") || lowercasedSport.contains("discgolf") {
            return "disc.golf"
        }

        // Rock Climbing
        if lowercasedSport.contains("rock climbing") || lowercasedSport.contains("rockclimbing") {
            return "figure.climbing"
        }

        // Bouldering
        if lowercasedSport.contains("bouldering") || lowercasedSport.contains("boulder") {
            return "figure.climbing"
        }

        // Parkour
        if lowercasedSport.contains("parkour") {
            return "figure.parkour"
        }

        // Breakdancing
        if
            lowercasedSport.contains("breakdancing") || lowercasedSport.contains("break dance") || lowercasedSport
                .contains("breakdance") {
            return "figure.dance"
        }

        // Hip Hop Dance
        if lowercasedSport.contains("hip hop") || lowercasedSport.contains("hiphop") {
            return "figure.dance"
        }

        // Ballet
        if lowercasedSport.contains("ballet") {
            return "figure.dance"
        }

        // Jazz Dance
        if lowercasedSport.contains("jazz dance") || lowercasedSport.contains("jazzdance") {
            return "figure.dance"
        }

        // Tap Dance
        if lowercasedSport.contains("tap dance") || lowercasedSport.contains("tapdance") {
            return "figure.dance"
        }

        // Contemporary Dance
        if lowercasedSport.contains("contemporary dance") || lowercasedSport.contains("contemporarydance") {
            return "figure.dance"
        }

        // Tai Chi
        if lowercasedSport.contains("tai chi") || lowercasedSport.contains("taichi") {
            return "figure.mind.and.body"
        }

        // Meditation
        if lowercasedSport.contains("meditation") || lowercasedSport.contains("meditate") {
            return "figure.mind.and.body"
        }

        // Kickboxing
        if lowercasedSport.contains("kickboxing") || lowercasedSport.contains("kickbox") {
            return "figure.martial.arts"
        }

        // Muay Thai
        if lowercasedSport.contains("muay thai") || lowercasedSport.contains("muaythai") {
            return "figure.martial.arts"
        }

        // Jiu-Jitsu
        if lowercasedSport.contains("jiu-jitsu") || lowercasedSport.contains("jiujitsu") {
            return "figure.martial.arts"
        }

        // Judo
        if lowercasedSport.contains("judo") {
            return "figure.martial.arts"
        }

        // Aikido
        if lowercasedSport.contains("aikido") {
            return "figure.martial.arts"
        }

        // Kendo
        if lowercasedSport.contains("kendo") {
            return "figure.martial.arts"
        }

        // Capoeira
        if lowercasedSport.contains("capoeira") {
            return "figure.martial.arts"
        }

        // Krav Maga
        if lowercasedSport.contains("krav maga") || lowercasedSport.contains("kravmaga") {
            return "figure.martial.arts"
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
