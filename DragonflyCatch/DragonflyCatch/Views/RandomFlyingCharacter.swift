import SwiftUI

struct RandomFlyingCharacter: View {
    let imageName: String
    let swingTrigger: Int
    let isStageCleared: Bool
    @State private var position: CGPoint
    @State private var facingLeft: Bool
    @State private var targetPosition: CGPoint
    @State private var movementDuration: Double
    @State private var movementSpeed: CGFloat
    @State private var flipDuration: Double
    @State private var netPosition: CGPoint
    @State private var netOpacity: Double = 0
    @State private var netRotation: Double = 0
    @State private var movementTimer: Timer?
    @State private var fadeOutWorkItem: DispatchWorkItem?

    let maxWidth: CGFloat
    let maxHeight: CGFloat

    init(imageName: String, maxWidth: CGFloat, maxHeight: CGFloat, swingTrigger: Int, isStageCleared: Bool) {
        self.imageName = imageName
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.swingTrigger = swingTrigger
        self.isStageCleared = isStageCleared
        let initialFacing = Bool.random()
        let initialPosition = RandomFlyingCharacter.randomPoint(maxWidth: maxWidth,
                                                                maxHeight: maxHeight,
                                                                currentX: maxWidth / 2,
                                                                facingLeft: initialFacing)
        self._position = State(initialValue: initialPosition)
        self._targetPosition = State(initialValue: initialPosition)
        self._facingLeft = State(initialValue: initialFacing)
        self._movementDuration = State(initialValue: 1.0)
        self._movementSpeed = State(initialValue: 100)
        self._flipDuration = State(initialValue: Double.random(in: 0.1...0.2))
        self._netPosition = State(initialValue: initialPosition)
    }

    var body: some View {
        ZStack {
            if isStageCleared {
                characterView
                netView
            } else {
                netView
                characterView
            }
        }
        .frame(width: maxWidth, height: maxHeight, alignment: .topLeading)
        .allowsHitTesting(false)
        .onAppear {
            scheduleNextMove()
        }
        .onChange(of: swingTrigger) { _ in
            guard !isStageCleared else { return }
            swingNet()
        }
        .onChange(of: isStageCleared) { cleared in
            if cleared {
                movementTimer?.invalidate()
                movementTimer = nil
                fadeOutWorkItem?.cancel()
                netPosition = position
                netOpacity = 1
            }
        }
    }

    private var netView: some View {
        Image("網")
            .resizable()
            .scaledToFit()
            .frame(width: maxWidth * 0.7)
            .scaleEffect(x: facingLeft ? 1 : -1, y: 1)
            .opacity(netOpacity)
            .rotationEffect(.degrees(netRotation))
            .position(netPosition)
    }

    private var characterView: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: maxWidth * 0.4)
            .scaleEffect(x: facingLeft ? 1 : -1, y: 1)
            .position(position)
    }

    private func scheduleNextMove() {
        guard !isStageCleared else { return }
        let newFacingLeft = Bool.random()
        let nextPoint = RandomFlyingCharacter.randomPoint(maxWidth: maxWidth,
                                                          maxHeight: maxHeight,
                                                          currentX: position.x,
                                                          facingLeft: newFacingLeft)
        targetPosition = nextPoint
        let speed = CGFloat.random(in: 80...140)
        movementSpeed = speed
        let distance = hypot(nextPoint.x - position.x, nextPoint.y - position.y)
        let moveDuration = max(0.3, Double(distance / speed))
        movementDuration = moveDuration

        if newFacingLeft != facingLeft {
            let flipDuration = Double.random(in: 0.1...0.2)
            self.flipDuration = flipDuration
            withAnimation(.easeInOut(duration: flipDuration)) {
                facingLeft = newFacingLeft
            }
        } else {
            facingLeft = newFacingLeft
        }

        animateMovement(to: nextPoint, duration: moveDuration) {
            scheduleNextMove()
        }
    }

    private func animateMovement(to target: CGPoint, duration: Double, completion: (() -> Void)? = nil) {
        movementTimer?.invalidate()
        let start = position
        let delta = CGPoint(x: target.x - start.x, y: target.y - start.y)
        let frames = max(5, Int(duration / (1.0 / 60.0)))
        var frame = 0
        let interval = max(duration / Double(frames), 1.0 / 120.0)

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if frame >= frames {
                position = target
                timer.invalidate()
                movementTimer = nil
                completion?()
                return
            }
            let progress = Double(frame) / Double(frames)
            position = CGPoint(x: start.x + delta.x * progress,
                               y: start.y + delta.y * progress)
            frame += 1
        }
        movementTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func swingNet() {
        let currentPosition = position
        withAnimation(.linear(duration: 0.02)) {
            netPosition = currentPosition
        }
        let offsetX = facingLeft ? maxWidth * 0.05 : -maxWidth * 0.05
        let offsetY = -maxHeight * 0.015
        let proposedX = currentPosition.x + offsetX
        let proposedY = currentPosition.y + offsetY
        let clampedX = min(max(proposedX, 20), maxWidth - 20)
        let clampedY = min(max(proposedY, 20), maxHeight - 20)
        netPosition = CGPoint(x: clampedX, y: clampedY)

        let startAngle = facingLeft ? 5.0 : -5.0
        let endAngle = facingLeft ? -85.0 : 85.0

        withAnimation(.easeOut(duration: 0.01)) {
            netOpacity = 1
            netRotation = startAngle
        }

        withAnimation(.easeOut(duration: 0.1).delay(0.01)) {
            netRotation = endAngle
        }

        fadeOutWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard !isStageCleared else { return }
            withAnimation(.easeIn(duration: 0.03)) {
                netOpacity = 0
            }
        }
        fadeOutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)

        if !isStageCleared {
            performDodgeMove()
        } else {
            netPosition = position
        }
    }

    private func performDodgeMove() {
        let distance = min(maxWidth, maxHeight) * 0.12
        let directions: [CGFloat] = [0, .pi / 2, .pi, 3 * .pi / 2]
        let angle = directions.randomElement() ?? 0
        let targetX = min(max(position.x + cos(angle) * distance, 20), maxWidth - 20)
        let targetY = min(max(position.y + sin(angle) * distance, 20), maxHeight - 20)
        let dodgeTarget = CGPoint(x: targetX, y: targetY)
        animateMovement(to: dodgeTarget, duration: 0.25) {
            scheduleNextMove()
        }
    }

    private static func randomPoint(maxWidth: CGFloat,
                                    maxHeight: CGFloat,
                                    currentX: CGFloat?,
                                    facingLeft: Bool?) -> CGPoint {
        let padding: CGFloat = 40
        let minX = padding
        let maxX = maxWidth - padding
        guard let currentX, let facingLeft else {
            let x = CGFloat.random(in: minX...maxX)
            let y = CGFloat.random(in: padding...(maxHeight - padding))
            return CGPoint(x: x, y: y)
        }

        let minStep: CGFloat = 60
        let maxStep: CGFloat = 160
        let step = CGFloat.random(in: minStep...maxStep) * (facingLeft ? -1 : 1)
        var x = currentX + step
        x = min(max(x, minX), maxX)
        let y = CGFloat.random(in: padding...(maxHeight - padding))
        return CGPoint(x: x, y: y)
    }
}
