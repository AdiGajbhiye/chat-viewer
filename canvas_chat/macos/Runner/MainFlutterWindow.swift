import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Open with the maximum real estate available: fill the screen's visible
    // frame (everything but the menu bar and Dock) instead of the small
    // default window frame.
    let windowFrame = NSScreen.main?.visibleFrame ?? self.frame
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
