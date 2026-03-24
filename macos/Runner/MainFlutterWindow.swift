import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    private let minWindowWidth: CGFloat = 400
    private let minWindowHeight: CGFloat = 600
    private let maxWindowWidth: CGFloat = 1280
    private let maxWindowHeight: CGFloat = 900
    private let screenRatio: CGFloat = 0.8

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        self.contentViewController = flutterViewController

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth = min(screenFrame.width * screenRatio, maxWindowWidth)
            let windowHeight = min(screenFrame.height * screenRatio, maxWindowHeight)
            
            let x = screenFrame.origin.x + (screenFrame.width - windowWidth) / 2
            let y = screenFrame.origin.y + (screenFrame.height - windowHeight) / 2
            
            let windowFrame = NSRect(x: x, y: y, width: windowWidth, height: windowHeight)
            self.setFrame(windowFrame, display: true)
        }

        self.minSize = NSSize(width: minWindowWidth, height: minWindowHeight)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
