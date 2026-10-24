// Vérification des calculs (lancée par la compilation automatique). Sort en erreur si un test échoue.
import Foundation

var echecs = 0
func verifier(_ ok: Bool, _ texte: String) {
    print((ok ? "OK     " : "ÉCHEC  ") + texte)
    if !ok { echecs += 1 }
}

verifier(abs(altitudePression(1013.25, qnh: 1013.25)) < 0.01, "1013,25 hPa au calage standard = 0 m")
let a900 = altitudePression(900, qnh: 1013.25)
verifier(abs(a900 - 988.5) < 3, "900 hPa ≈ 988 m (obtenu \(Int(a900)) m)")
let q = qnhPour(pression: 950, altitude: 650)
verifier(abs(altitudePression(950, qnh: q) - 650) < 0.01, "calage puis altitude : on retrouve 650 m")

// Filtre : palier de +2 m/s mesuré 4 fois par seconde avec un bruit de ±0,3 m
var f = FiltreVario()
var graine: UInt64 = 42
func bruit() -> Double {               // bruit pseudo-aléatoire reproductible, ~ ±0,3 m
    graine = graine &* 6364136223846793005 &+ 1442695040888963407
    return (Double(graine >> 11) / Double(1 << 53) - 0.5) * 1.0
}
var t = 0.0, v = 0.0, maxCalme = 0.0
while t < 40 {
    let h = 1000 + (t < 20 ? 0 : 2 * (t - 20))
    v = f.mesure(temps: t, altitude: h + bruit())
    if t > 5 && t < 20 { maxCalme = max(maxCalme, abs(v)) }
    t += 0.25
}
verifier(maxCalme < 0.5, "air calme : le vario reste sous 0,5 m/s (max \(String(format: "%.2f", maxCalme)))")
verifier(abs(v - 2) < 0.3, "montée de 2 m/s retrouvée (\(String(format: "%.2f", v)) m/s)")

var m = MoyenneGlissante(duree: 20)
var moy: Double? = nil
for i in 0...100 { moy = m.ajouter(temps: Double(i) * 0.5, altitude: 500 + Double(i) * 0.5 * 1.5) }
verifier(moy != nil && abs(moy! - 1.5) < 0.01, "moyenne sur 20 s : 1,5 m/s")

verifier(!SonVario.pour(vitesse: 0, seuilMontee: 0.2, seuilDescente: -2.5).actif, "pas de son à 0 m/s")
let s1 = SonVario.pour(vitesse: 1, seuilMontee: 0.2, seuilDescente: -2.5)
let s3 = SonVario.pour(vitesse: 3, seuilMontee: 0.2, seuilDescente: -2.5)
verifier(s1.actif && s3.frequence > s1.frequence && s3.periode < s1.periode, "plus ça monte, plus c'est aigu et rapide")
verifier(SonVario.pour(vitesse: -3, seuilMontee: 0.2, seuilDescente: -2.5).periode == 0, "forte descente : son continu")

print(echecs == 0 ? "Tous les calculs sont justes." : "\(echecs) test(s) en échec.")
exit(echecs == 0 ? 0 : 1)
