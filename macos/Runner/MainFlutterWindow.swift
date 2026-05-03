import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    private let defaultWindowWidth: CGFloat = 430
    private let defaultWindowHeight: CGFloat = 900
    private let minWindowWidth: CGFloat = 360
    private let minWindowHeight: CGFloat = 640
    private let maxWindowWidth: CGFloat = 600
    private let maxWindowHeight: CGFloat = 1100

    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        self.contentViewController = flutterViewController

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.origin.x + (screenFrame.width - defaultWindowWidth) / 2
            let y = screenFrame.origin.y + (screenFrame.height - defaultWindowHeight) / 2
            self.setFrame(
                NSRect(x: x, y: y, width: defaultWindowWidth, height: defaultWindowHeight),
                display: true
            )
        }

        self.minSize = NSSize(width: minWindowWidth, height: minWindowHeight)
        self.maxSize = NSSize(width: maxWindowWidth, height: maxWindowHeight)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
