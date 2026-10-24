// Son du vario : générateur sinusoïdal (AVAudioEngine), bips cadencés, sans coupure audible.
import AVFoundation

/// Réglages lus par le fil audio (écrits depuis l'interface) et état du générateur.
final class EtatSon {
    var cible = SonVario.silence
    var phase = 0.0
    var tempsCycle = 0.0
    var amplitude: Float = 0
    var frequence = 0.0
}

final class Son {
    private let moteur = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private let etat = EtatSon()
    private(set) var demarre = false

    func regler(_ s: SonVario) { etat.cible = s }

    func demarrer() {
        guard !demarre else { return }
        let session = AVAudioSession.sharedInstance()
        // .playback + mixWithOthers : le son continue écran verrouillé et se mêle à la musique ou à la radio.
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
        let frequenceEchantillons = session.sampleRate > 0 ? session.sampleRate : 44100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: frequenceEchantillons, channels: 1) else { return }
        let e = etat
        let pas = 1.0 / frequenceEchantillons
        let noeud = AVAudioSourceNode(format: format) { _, _, nombre, listeTampons -> OSStatus in
            let tampons = UnsafeMutableAudioBufferListPointer(listeTampons)
            let cible = e.cible
            for i in 0..<Int(nombre) {
                // Bip : son pendant la moitié de la période ; période 0 = son continu.
                var allume = cible.actif
                if cible.actif && cible.periode > 0 {
                    e.tempsCycle += pas
                    if e.tempsCycle >= cible.periode { e.tempsCycle = 0 }
                    allume = e.tempsCycle < cible.periode * 0.5
                }
                let viseAmplitude: Float = allume ? 0.6 : 0
                e.amplitude += (viseAmplitude - e.amplitude) * 0.004          // fondu de ~5 ms : pas de clic
                if cible.frequence > 0 { e.frequence += (cible.frequence - e.frequence) * 0.002 }
                e.phase += 2 * Double.pi * e.frequence * pas
                if e.phase > 2 * Double.pi { e.phase -= 2 * Double.pi }
                let valeur = e.amplitude * Float(sin(e.phase))
                for tampon in tampons {
                    tampon.mData?.assumingMemoryBound(to: Float.self)[i] = valeur
                }
            }
            return noErr
        }
        source = noeud
        moteur.attach(noeud)
        moteur.connect(noeud, to: moteur.mainMixerNode, format: format)
        do { try moteur.start(); demarre = true } catch { demarre = false }
    }
}
