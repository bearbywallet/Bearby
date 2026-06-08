import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    private let defaultWindowWidth: CGFloat = 430
    private let defaultWindowHeight: CGFloat = 900
    private let minWindowWidth: CGFloat = 360
    private let minWindowHeight: CGFloat = 640


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

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
