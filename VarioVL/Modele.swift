// Capteurs (baromètre, GPS) et calculs en direct.
import SwiftUI
import CoreMotion
import CoreLocation

final class Modele: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Affichage
    @Published var vario = 0.0                       // m/s
    @Published var moyenne20s: Double? = nil         // m/s
    @Published var altitude: Double? = nil           // m, baromètre calé
    @Published var pression: Double? = nil           // hPa
    @Published var altitudeGPS: Double? = nil        // m
    @Published var precisionVerticaleGPS: Double? = nil
    @Published var vitesseSol: Double? = nil         // km/h
    @Published var cap: Double? = nil                // degrés
    @Published var mesuresParSeconde = 0.0
    @Published var calage = "standard (1013,25 hPa)"
    @Published var baroDisponible = CMAltimeter.isRelativeAltitudeAvailable()
    @Published var message = ""
    // Réglages (mémorisés)
    private static let reglages = UserDefaults.standard
    @Published var sonActif = Modele.lire("sonActif", true) { didSet { Modele.reglages.set(sonActif, forKey: "sonActif"); majSon() } }
    @Published var seuilMontee = Modele.lire("seuilMontee", 0.2) { didSet { Modele.reglages.set(seuilMontee, forKey: "seuilMontee"); majSon() } }
    @Published var seuilDescente = Modele.lire("seuilDescente", -2.5) { didSet { Modele.reglages.set(seuilDescente, forKey: "seuilDescente"); majSon() } }
    @Published var reactivite = Modele.lire("reactivite", 0.4) { didSet { Modele.reglages.set(reactivite, forKey: "reactivite"); filtre.q = reactivite } }
    @Published var qnh = Modele.lire("qnh", 1013.25) { didSet { Modele.reglages.set(qnh, forKey: "qnh") } }

    private static func lire<T>(_ cle: String, _ defaut: T) -> T {
        return (reglages.object(forKey: cle) as? T) ?? defaut
    }

    private let altimetre = CMAltimeter()
    private let localisation = CLLocationManager()
    private var filtre = FiltreVario()
    private var moyenne = MoyenneGlissante(duree: 20)
    private var instants: [Double] = []
    private let son = Son()
    private var calageAutoFait = false
    private var derniereLocalisation: CLLocation?

    func demarrer() {
        UIApplication.shared.isIdleTimerDisabled = true            // écran toujours allumé
        filtre.q = reactivite
        if qnh != 1013.25 { calage = String(format: "%.2f hPa (calage précédent)", qnh) }
        son.demarrer()
        localisation.delegate = self
        localisation.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        localisation.activityType = .airborne
        localisation.pausesLocationUpdatesAutomatically = false
        localisation.requestWhenInUseAuthorization()
        localisation.allowsBackgroundLocationUpdates = true        // GPS et son écran verrouillé
        localisation.showsBackgroundLocationIndicator = true
        localisation.startUpdatingLocation()
        localisation.startUpdatingHeading()
        guard baroDisponible else {
            message = "Baromètre indisponible sur cet appareil."
            return
        }
        altimetre.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] donnees, erreur in
            guard let self = self else { return }
            if let erreur = erreur { self.message = "Baromètre : \(erreur.localizedDescription)"; return }
            guard let d = donnees else { return }
            self.recevoir(pressionKPa: d.pressure.doubleValue, temps: d.timestamp)
        }
    }

    private func recevoir(pressionKPa: Double, temps: TimeInterval) {
        let p = pressionKPa * 10
        pression = p
        let h = altitudePression(p, qnh: qnh)
        vario = filtre.mesure(temps: temps, altitude: h)
        altitude = filtre.altitude
        moyenne20s = moyenne.ajouter(temps: temps, altitude: h)
        instants.append(temps)
        while let premier = instants.first, temps - premier > 5 { instants.removeFirst() }
        if instants.count > 1, let premier = instants.first, temps > premier {
            mesuresParSeconde = Double(instants.count - 1) / (temps - premier)
        }
        majSon()
    }

    private func majSon() {
        son.regler(sonActif ? SonVario.pour(vitesse: vario, seuilMontee: seuilMontee, seuilDescente: seuilDescente) : .silence)
    }

    // MARK: Calage de l'altimètre
    func calerSur(altitude alt: Double, origine: String) {
        guard let p = pression else { message = "Pas encore de mesure de pression."; return }
        qnh = qnhPour(pression: p, altitude: alt)
        calage = String(format: "%@ : %.0f m (%.2f hPa)", origine, alt, qnh)
        filtre.reinitialiser(); moyenne.vider()
        message = ""
    }

    func calerSurGPS() {
        guard let l = derniereLocalisation, l.verticalAccuracy > 0 else { message = "GPS pas encore prêt."; return }
        calerSur(altitude: l.altitude, origine: "GPS")
    }

    // MARK: GPS
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        derniereLocalisation = l
        if l.verticalAccuracy > 0 {
            altitudeGPS = l.altitude
            precisionVerticaleGPS = l.verticalAccuracy
            // Premier calage automatique sur le GPS, s'il est assez précis et qu'aucun calage n'existe.
            if !calageAutoFait && qnh == 1013.25 && l.verticalAccuracy <= 15 && pression != nil {
                calageAutoFait = true
                calerSur(altitude: l.altitude, origine: "GPS (auto)")
            }
        }
        vitesseSol = l.speed >= 0 ? l.speed * 3.6 : nil
        if l.course >= 0 { cap = l.course }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        message = "GPS : \(error.localizedDescription)"
    }
}
