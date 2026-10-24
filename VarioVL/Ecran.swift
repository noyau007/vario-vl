// Écran unique : vario en grand, altitudes, GPS, réglages.
import SwiftUI

struct Ecran: View {
    @EnvironmentObject var m: Modele
    @State private var reglages = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Text("Vario VL").font(.headline).foregroundColor(.gray)
                    Spacer()
                    Button { m.sonActif.toggle() } label: {
                        Image(systemName: m.sonActif ? "speaker.wave.2.fill" : "speaker.slash.fill").font(.title2)
                    }
                    Button { reglages = true } label: { Image(systemName: "gearshape.fill").font(.title2) }
                        .padding(.leading, 12)
                }
                .foregroundColor(.white)

                // Vario
                Text(signe(m.vario, decimales: 1))
                    .font(.system(size: 110, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(couleur(m.vario))
                    .minimumScaleFactor(0.5)
                Text("m/s").foregroundColor(.gray)
                HStack {
                    Bloc(titre: "moyenne 20 s", valeur: m.moyenne20s.map { signe($0, decimales: 1) } ?? "–", unite: "m/s")
                    Bloc(titre: "altitude", valeur: m.altitude.map { entier($0) } ?? "–", unite: "m")
                }
                HStack {
                    Bloc(titre: "vitesse sol", valeur: m.vitesseSol.map { entier($0) } ?? "–", unite: "km/h")
                    Bloc(titre: "cap", valeur: m.cap.map { entier($0) + "°" } ?? "–", unite: "")
                }
                HStack {
                    Bloc(titre: "altitude GPS", valeur: m.altitudeGPS.map { entier($0) } ?? "–",
                         unite: m.precisionVerticaleGPS.map { "m ±" + entier($0) } ?? "m")
                    Bloc(titre: "pression", valeur: m.pression.map { String(format: "%.1f", $0) } ?? "–", unite: "hPa")
                }
                Text("Calage : \(m.calage) · \(String(format: "%.1f", m.mesuresParSeconde)) mesures/s")
                    .font(.footnote).foregroundColor(.gray).multilineTextAlignment(.center)
                if !m.message.isEmpty {
                    Text(m.message).font(.footnote).foregroundColor(.orange).multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)
            }
            .padding()
        }
        .sheet(isPresented: $reglages) { Reglages().environmentObject(m) }
        .preferredColorScheme(.dark)
    }
}

struct Bloc: View {
    let titre: String, valeur: String, unite: String
    var body: some View {
        VStack(spacing: 2) {
            Text(titre).font(.caption).foregroundColor(.gray)
            Text(valeur).font(.system(size: 34, weight: .semibold, design: .rounded)).monospacedDigit()
                .foregroundColor(.white).minimumScaleFactor(0.5).lineLimit(1)
            Text(unite).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

struct Reglages: View {
    @EnvironmentObject var m: Modele
    @Environment(\.dismiss) private var fermer
    @State private var altitudeSaisie = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Calage de l'altimètre"), footer: Text(m.calage)) {
                    Button("Caler sur le GPS") { m.calerSurGPS() }
                    HStack {
                        TextField("Altitude connue (m), ex. déco", text: $altitudeSaisie).keyboardType(.numberPad)
                        Button("Caler") {
                            if let a = Double(altitudeSaisie.replacingOccurrences(of: ",", with: ".")) {
                                m.calerSur(altitude: a, origine: "saisie")
                            }
                        }
                    }
                }
                Section(header: Text("Son")) {
                    Toggle("Son du vario", isOn: $m.sonActif)
                    VStack(alignment: .leading) {
                        Text("Bips à partir de " + signe(m.seuilMontee, decimales: 1) + " m/s")
                        Slider(value: $m.seuilMontee, in: 0.0...1.0, step: 0.1)
                    }
                    VStack(alignment: .leading) {
                        Text("Alarme de descente sous " + signe(m.seuilDescente, decimales: 1) + " m/s")
                        Slider(value: $m.seuilDescente, in: -6.0...(-1.0), step: 0.5)
                    }
                }
                Section(header: Text("Vario"), footer: Text("Plus réactif = réagit plus vite, mais bouge davantage en air calme.")) {
                    VStack(alignment: .leading) {
                        Text("Réactivité : " + String(format: "%.1f", m.reactivite))
                        Slider(value: $m.reactivite, in: 0.1...2.0, step: 0.1)
                    }
                }
                Section(footer: Text("Aide au vol, ne remplace pas un instrument certifié. L'écran reste allumé ; le son et le GPS continuent écran verrouillé.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Réglages")
            .toolbar { Button("OK") { fermer() } }
        }
    }
}

func signe(_ v: Double, decimales: Int) -> String {
    let texte = String(format: "%.\(decimales)f", abs(v)).replacingOccurrences(of: ".", with: ",")
    let nul = abs(v) < 0.5 * pow(10, -Double(decimales))
    return (nul ? "" : (v > 0 ? "+" : "−")) + texte
}

func entier(_ v: Double) -> String { String(Int(v.rounded())) }

func couleur(_ v: Double) -> Color {
    if v >= 0.5 { return .green }
    if v <= -2 { return .red }
    return .white
}
