import Foundation
import BitmovinPlayer

class PlayerView2: PlayerView {
    override init(player: Player, frame: CGRect) {
        super.init(player: player, frame: frame)
    }
    
    func setZoom(state: Bool) {
        let layer = self.layer as! AVPlayerLayer
        if (state == true) {
            frame.applying(CGAffineTransform(scaleX: 2, y: 2))
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        } else {
            frame.applying(CGAffineTransform(scaleX: 0.5, y: 0.5))
            layer.videoGravity = AVLayerVideoGravity.resizeAspect
        }
    }
}
