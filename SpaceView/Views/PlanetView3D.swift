import SwiftUI
import SceneKit

struct PlanetView3D: UIViewRepresentable {
    let planet: Planet

    func makeCoordinator() -> Coordinator { Coordinator(planet: planet) }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.scene = buildScene(for: planet)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard context.coordinator.currentPlanet != planet else { return }
        context.coordinator.currentPlanet = planet
        uiView.scene = buildScene(for: planet)
    }

    // MARK: - Scene

    private func buildScene(for planet: Planet) -> SCNScene {
        let scene = SCNScene()

        // Planet node
        let sphere = SCNSphere(radius: 1.0)
        let mat = SCNMaterial()
        mat.diffuse.contents = planetColor(planet)
        mat.specular.contents = UIColor.white
        mat.shininess = 35
        sphere.materials = [mat]
        let planetNode = SCNNode(geometry: sphere)

        // Axial tilt
        planetNode.eulerAngles.z = axialTilt(planet)

        // Auto-spin
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.toValue = NSValue(scnVector4: SCNVector4(0, 1, 0, Float.pi * 2))
        spin.duration = spinDuration(planet)
        spin.repeatCount = .infinity
        planetNode.addAnimation(spin, forKey: "spin")

        scene.rootNode.addChildNode(planetNode)

        // Saturn rings
        if planet == .saturn {
            scene.rootNode.addChildNode(saturnRings(parentTilt: axialTilt(planet)))
        }

        // Uranus faint rings
        if planet == .uranus {
            scene.rootNode.addChildNode(uranusRings())
        }

        // Lighting: soft ambient + directional "sun"
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.18, alpha: 1)
        let ambientNode = SCNNode(); ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let sun = SCNLight()
        sun.type = .directional
        sun.color = UIColor(white: 1.0, alpha: 1)
        sun.intensity = 900
        let sunNode = SCNNode()
        sunNode.light = sun
        sunNode.position = SCNVector3(5, 3, 5)
        scene.rootNode.addChildNode(sunNode)

        // Camera
        let cam = SCNCamera()
        cam.fieldOfView = 55
        let camNode = SCNNode()
        camNode.camera = cam
        camNode.position = SCNVector3(0, 0, planet == .saturn ? 4.8 : 3.2)
        scene.rootNode.addChildNode(camNode)

        return scene
    }

    // MARK: - Rings

    private func saturnRings(parentTilt: Float) -> SCNNode {
        let container = SCNNode()
        container.eulerAngles.z = parentTilt

        let torus = SCNTorus(ringRadius: 1.72, pipeRadius: 0.20)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.84, green: 0.76, blue: 0.54, alpha: 0.72)
        mat.isDoubleSided = true
        torus.materials = [mat]
        let ringNode = SCNNode(geometry: torus)
        ringNode.eulerAngles.x = 0.44
        container.addChildNode(ringNode)
        return container
    }

    private func uranusRings() -> SCNNode {
        let torus = SCNTorus(ringRadius: 1.48, pipeRadius: 0.045)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(white: 0.55, alpha: 0.38)
        mat.isDoubleSided = true
        torus.materials = [mat]
        let node = SCNNode(geometry: torus)
        node.eulerAngles.x = Float.pi / 2   // Uranus rolls on its side
        return node
    }

    // MARK: - Per-planet properties

    private func planetColor(_ p: Planet) -> UIColor {
        switch p {
        case .mercury: return UIColor(red: 0.60, green: 0.56, blue: 0.52, alpha: 1)
        case .venus:   return UIColor(red: 0.92, green: 0.82, blue: 0.55, alpha: 1)
        case .earth:   return UIColor(red: 0.18, green: 0.52, blue: 0.80, alpha: 1)
        case .mars:    return UIColor(red: 0.78, green: 0.32, blue: 0.18, alpha: 1)
        case .jupiter: return UIColor(red: 0.82, green: 0.66, blue: 0.50, alpha: 1)
        case .saturn:  return UIColor(red: 0.90, green: 0.83, blue: 0.62, alpha: 1)
        case .uranus:  return UIColor(red: 0.48, green: 0.84, blue: 0.90, alpha: 1)
        case .neptune: return UIColor(red: 0.20, green: 0.40, blue: 0.92, alpha: 1)
        }
    }

    private func spinDuration(_ p: Planet) -> Double {
        switch p {
        case .mercury: return 22
        case .venus:   return 30
        case .earth:   return 14
        case .mars:    return 15
        case .jupiter: return 8
        case .saturn:  return 9
        case .uranus:  return 16
        case .neptune: return 18
        }
    }

    /// Axial tilt in radians (z-axis rotation of the planet node)
    private func axialTilt(_ p: Planet) -> Float {
        switch p {
        case .mercury: return 0.03
        case .venus:   return 3.09
        case .earth:   return 0.41
        case .mars:    return 0.44
        case .jupiter: return 0.05
        case .saturn:  return 0.47
        case .uranus:  return 1.71
        case .neptune: return 0.49
        }
    }

    // MARK: - Coordinator

    class Coordinator {
        var currentPlanet: Planet
        init(planet: Planet) { self.currentPlanet = planet }
    }
}
