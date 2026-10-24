// Calculs du vario, sans dépendance à iOS (vérifiés à chaque compilation par Verification/main.swift).
import Foundation

/// Altitude (m) donnée par la pression `p` (hPa) pour un calage `qnh` (hPa), atmosphère standard.
func altitudePression(_ p: Double, qnh: Double) -> Double {
    return 44330.77 * (1.0 - pow(p / qnh, 0.190263))
}

/// Calage (hPa) qui fait correspondre la pression `p` (hPa) à l'altitude `altitude` (m).
func qnhPour(pression p: Double, altitude: Double) -> Double {
    return p / pow(1.0 - altitude / 44330.77, 1.0 / 0.190263)
}

/// Filtre de Kalman à deux états (altitude, vitesse verticale), pour des mesures à intervalles variables.
/// q : variance de l'accélération verticale (m²/s⁴) — plus grand = plus réactif mais plus nerveux.
/// r : variance du bruit de mesure de l'altitude (m²).
struct FiltreVario {
    var q: Double = 0.4
    var r: Double = 0.09
    private(set) var altitude: Double? = nil
    private(set) var vitesse: Double = 0
    private var p00 = 100.0, p01 = 0.0, p10 = 0.0, p11 = 10.0
    private var t = 0.0

    mutating func reinitialiser() {
        altitude = nil; vitesse = 0
        p00 = 100; p01 = 0; p10 = 0; p11 = 10
    }

    /// Ajoute une mesure d'altitude `z` (m) prise à l'instant `temps` (s) ; renvoie la vitesse verticale (m/s).
    @discardableResult
    mutating func mesure(temps: Double, altitude z: Double) -> Double {
        guard let h0 = altitude else { altitude = z; t = temps; return vitesse }
        let dt = max(0.001, min(5.0, temps - t))
        t = temps
        // Prédiction
        let h = h0 + vitesse * dt
        let a00 = p00 + dt * (p10 + p01) + dt * dt * p11 + q * pow(dt, 4) / 4
        let a01 = p01 + dt * p11 + q * pow(dt, 3) / 2
        let a10 = p10 + dt * p11 + q * pow(dt, 3) / 2
        let a11 = p11 + q * dt * dt
        // Correction
        let s = a00 + r
        let k0 = a00 / s, k1 = a10 / s
        let ecart = z - h
        altitude = h + k0 * ecart
        vitesse += k1 * ecart
        p00 = (1 - k0) * a00; p01 = (1 - k0) * a01
        p10 = a10 - k1 * a00; p11 = a11 - k1 * a01
        return vitesse
    }
}

/// Vitesse verticale moyenne sur les `duree` dernières secondes (différence d'altitude / temps).
struct MoyenneGlissante {
    var duree: Double = 20
    private var points: [(t: Double, h: Double)] = []

    mutating func ajouter(temps: Double, altitude: Double) -> Double? {
        points.append((temps, altitude))
        while let premier = points.first, temps - premier.t > duree { points.removeFirst() }
        guard let premier = points.first, temps - premier.t >= duree * 0.5 else { return nil }
        return (altitude - premier.h) / (temps - premier.t)
    }

    mutating func vider() { points.removeAll() }
}

/// Son du vario : fréquence (Hz), période des bips (s, 0 = son continu), et s'il faut jouer.
struct SonVario: Equatable {
    var frequence: Double
    var periode: Double
    var actif: Bool

    static let silence = SonVario(frequence: 0, periode: 0, actif: false)

    /// Bips de plus en plus aigus et rapprochés en montée ; son continu grave sous le seuil de descente.
    static func pour(vitesse v: Double, seuilMontee: Double, seuilDescente: Double) -> SonVario {
        if v >= seuilMontee {
            let f = min(1600, 650 + 110 * v)
            let periode = max(0.14, 0.55 - 0.06 * v)
            return SonVario(frequence: f, periode: periode, actif: true)
        }
        if v <= seuilDescente {
            let f = max(180, 380 + 25 * (v - seuilDescente))
            return SonVario(frequence: f, periode: 0, actif: true)
        }
        return .silence
    }
}
