import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = CustomFlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    self.minSize = NSSize(width: 300, height: 400)

    backgroundColor = NSColor(
      red: 0.10,
      green: 0.11,
      blue: 0.14,
      alpha: 1.0
    )

    isOpaque = true
    hasShadow = true

    super.awakeFromNib()
  }
}

class CustomFlutterViewController: FlutterViewController {
  override func loadView() {
    super.loadView()
    
    let flutterView = self.view
    let containerView = NSView() 
    containerView.wantsLayer = true
    
    self.view = containerView
    
    containerView.addSubview(flutterView)
    flutterView.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
      flutterView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      flutterView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      flutterView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      flutterView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8)
    ])
  }
}