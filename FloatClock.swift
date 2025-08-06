// The MIT License

// Copyright (c) 2018 Daniel
// Copyright (c) 2023 Roman Dubtsov
// Copyright (c) 2025 honsiorovskyi

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// How to build:
// $ swiftc -o clock -gnone -O -target x86_64-apple-macosx10.14 clock.swift
// How to run:
// $ ./clock

import Cocoa
import Foundation

class ClickableView: NSView {
    var onMouseDown: (() -> Void)?
    
    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
    }
}

class Clock: NSObject, NSApplicationDelegate {
    private var clockWindow: NSWindow?
    private var mouseTracker: Any?
    private var isHidden = true
    
    // Configuration constants
    private struct Config {
        static let windowMargin: CGFloat = 5
        static let dockHeightOffset: CGFloat = 15
        static let defaultWindowHeight: CGFloat = 45
        static let fontScaleFactor: CGFloat = 0.35  // Reduced from 0.5 to make fonts smaller
        static let minFontSize: CGFloat = 10        // Reduced from 12
        static let cornerRadius: CGFloat = 15
        static let mouseShowThreshold: CGFloat = 2
        static let horizontalPadding: CGFloat = 16  // Padding inside window for labels
        static let minWindowWidth: CGFloat = 80     // Minimum window width
    }

    func updateWindowPosition() {
        guard let screen = NSScreen.main,
              let window = clockWindow else { return }
        let newOrigin = NSPoint(
            x: screen.frame.width - window.frame.width - Config.windowMargin,
            y: Config.windowMargin
        )
        window.setFrameOrigin(newOrigin)
    }
    
    private func adjustWindowSizeForContent() {
        guard let window = clockWindow,
              let containerView = window.contentView as? ClickableView else { return }
        
        // Find the time and date labels
        var timeLabel: NSTextField?
        var dateLabel: NSTextField?
        
        for subview in containerView.subviews {
            if let textField = subview as? NSTextField {
                if textField.font?.fontName.contains("Mono") == true {
                    timeLabel = textField
                } else {
                    dateLabel = textField
                }
            }
        }
        
        guard let time = timeLabel, let date = dateLabel else { return }
        
        // Recalculate optimal width
        let newWidth = calculateOptimalWindowWidth(timeLabel: time, dateLabel: date)
        let currentFrame = window.frame
        
        // Only resize if width has changed significantly
        if abs(newWidth - currentFrame.width) > 1 {
            let newFrame = NSRect(
                x: currentFrame.maxX - newWidth, // Keep right edge in same position
                y: currentFrame.minY,
                width: newWidth,
                height: currentFrame.height
            )
            
            window.setFrame(newFrame, display: true, animate: false)
            
            // Reposition labels within the new container
            repositionLabels(timeLabel: time, dateLabel: date, containerSize: NSSize(width: newWidth, height: currentFrame.height))
        }
    }
    
    private func repositionLabels(timeLabel: NSTextField, dateLabel: NSTextField, containerSize: NSSize) {
        // Size the labels to fit their content
        timeLabel.sizeToFit()
        dateLabel.sizeToFit()
        
        // Calculate positions for stacked labels
        let totalHeight = timeLabel.frame.height + dateLabel.frame.height + 2 // 2px spacing
        let startY = (containerSize.height - totalHeight) / 2
        
        // Position time label (top)
        let timeLabelX = (containerSize.width - timeLabel.frame.width) / 2
        let timeLabelY = startY + dateLabel.frame.height + 2
        timeLabel.frame = NSRect(x: timeLabelX, y: timeLabelY, width: timeLabel.frame.width, height: timeLabel.frame.height)
        
        // Position date label (bottom)
        let dateLabelX = (containerSize.width - dateLabel.frame.width) / 2
        let dateLabelY = startY
        dateLabel.frame = NSRect(x: dateLabelX, y: dateLabelY, width: dateLabel.frame.width, height: dateLabel.frame.height)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initTimeDisplay()
        setupMouseTracking()
        setupScreenChangeNotifications()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        cleanupResources()
    }
    
    private func setupScreenChangeNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: NSApplication.shared,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowPosition()
        }
    }
    
    private func cleanupResources() {
        if let tracker = mouseTracker {
            NSEvent.removeMonitor(tracker)
            mouseTracker = nil
        }
    }
    
    private func setupMouseTracking() {
        mouseTracker = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self = self,
                  let window = self.clockWindow else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            let windowHeight = window.frame.height
            let hideThreshold = windowHeight + Config.windowMargin + 5 // Include margins plus extra 5px
            
            if mouseLocation.y <= Config.mouseShowThreshold && self.isHidden {
                self.showWindow()
            } else if mouseLocation.y > hideThreshold && !self.isHidden {
                self.hideWindow()
            }
        }
    }
    
    private func showWindow() {
        clockWindow?.orderFrontRegardless()
        clockWindow?.alphaValue = 1.0
        clockWindow?.ignoresMouseEvents = false  // Enable clicks when visible
        isHidden = false
    }
    
    private func hideWindow() {
        clockWindow?.alphaValue = 0.0
        clockWindow?.ignoresMouseEvents = true   // Disable clicks when hidden
        isHidden = true
    }

    private func getDockHeight() -> CGFloat {
        guard let dockDefaults = UserDefaults(suiteName: "com.apple.dock"),
              dockDefaults.integer(forKey: "tilesize") > 0 else {
            return Config.defaultWindowHeight
        }
        return CGFloat(dockDefaults.integer(forKey: "tilesize")) + Config.dockHeightOffset
    }
    
    private func calculateFontSize(for windowHeight: CGFloat) -> CGFloat {
        return max(Config.minFontSize, windowHeight * Config.fontScaleFactor)
    }
    
    private func calculateOptimalWindowWidth(timeLabel: NSTextField, dateLabel: NSTextField) -> CGFloat {
        timeLabel.sizeToFit()
        dateLabel.sizeToFit()
        
        let maxLabelWidth = max(timeLabel.frame.width, dateLabel.frame.width)
        let optimalWidth = maxLabelWidth + Config.horizontalPadding
        
        return max(optimalWidth, Config.minWindowWidth)
    }
    
    private func createContainerView(size: NSSize) -> ClickableView {
        let containerView = ClickableView(frame: NSRect(origin: .zero, size: size))
        containerView.wantsLayer = true
        
        // Set up click handler to open Calendar
        containerView.onMouseDown = { [weak self] in
            self?.openCalendarApp()
        }
        
        // Background and corner radius
        containerView.layer?.backgroundColor = NSColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0).cgColor
        containerView.layer?.cornerRadius = Config.cornerRadius
        containerView.layer?.masksToBounds = true
        
        // Outer border
        containerView.layer?.borderWidth = 0.1
        containerView.layer?.borderColor = NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8).cgColor
        
        // Inner border
        let innerBorderView = NSView(frame: NSRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2))
        innerBorderView.wantsLayer = true
        innerBorderView.layer?.backgroundColor = NSColor.clear.cgColor
        innerBorderView.layer?.cornerRadius = Config.cornerRadius - 1
        innerBorderView.layer?.borderWidth = 0.1
        innerBorderView.layer?.borderColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6).cgColor
        containerView.addSubview(innerBorderView)
        
        return containerView
    }
    
    private func openCalendarApp() {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Calendar.app"), 
                                         configuration: NSWorkspace.OpenConfiguration(), 
                                         completionHandler: nil)
    }

    func initLabel(font: NSFont, format: String, interval: TimeInterval) -> NSTextField {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let label = NSTextField()
        label.font = font
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.alignment = .center
        label.textColor = NSColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1.0)

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            label.stringValue = formatter.string(from: Date())
        }
        timer.tolerance = interval / 10
        timer.fire()

        return label
    }
    
    func initDateLabel(font: NSFont) -> NSTextField {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"

        let label = NSTextField()
        label.font = font
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.alignment = .center
        label.textColor = NSColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1.0)

        let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            label.stringValue = formatter.string(from: Date())
            self?.adjustWindowSizeForContent()
        }
        timer.tolerance = 6
        timer.fire()

        return label
    }

    func initWindow(rect: NSRect, timeLabel: NSTextField, dateLabel: NSTextField) -> NSWindow {
        let window = NSWindow(
            contentRect : rect,
            styleMask   : .borderless,
            backing     : .buffered,
            defer       : true
        )

        window.ignoresMouseEvents = true  // Start with mouse events disabled (hidden state)
        window.level = .floating
        window.collectionBehavior = .canJoinAllSpaces
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.hasShadow = true
        
        let containerView = createContainerView(size: rect.size)
        
        // Size the labels
        timeLabel.sizeToFit()
        dateLabel.sizeToFit()
        
        // Calculate positions for stacked labels
        let totalHeight = timeLabel.frame.height + dateLabel.frame.height + 2 // 2px spacing
        let startY = (containerView.bounds.height - totalHeight) / 2
        
        // Position time label (top)
        let timeLabelX = (containerView.bounds.width - timeLabel.frame.width) / 2
        let timeLabelY = startY + dateLabel.frame.height + 2
        timeLabel.frame = NSRect(x: timeLabelX, y: timeLabelY, width: timeLabel.frame.width, height: timeLabel.frame.height)
        
        // Position date label (bottom)
        let dateLabelX = (containerView.bounds.width - dateLabel.frame.width) / 2
        let dateLabelY = startY
        dateLabel.frame = NSRect(x: dateLabelX, y: dateLabelY, width: dateLabel.frame.width, height: dateLabel.frame.height)
        
        containerView.addSubview(timeLabel)
        containerView.addSubview(dateLabel)
        
        window.contentView = containerView
        window.orderFrontRegardless()

        return window
    }

    func initTimeDisplay() {
        let windowHeight = getDockHeight()
        let timeFontSize = calculateFontSize(for: windowHeight)
        let dateFontSize = timeFontSize * 0.7 // Make date smaller than time
        
        let timeFont = NSFont.monospacedDigitSystemFont(ofSize: timeFontSize, weight: .regular)
        let dateFont = NSFont.systemFont(ofSize: dateFontSize, weight: .regular)
        
        let timeLabel = initLabel(font: timeFont, format: "hh:mm", interval: 1)
        let dateLabel = initDateLabel(font: dateFont)
        
        // Calculate optimal window width based on label content
        let windowWidth = calculateOptimalWindowWidth(timeLabel: timeLabel, dateLabel: dateLabel)

        guard let screen = NSScreen.main else { return }
        
        let rect = NSRect(
            x: screen.frame.width - windowWidth - Config.windowMargin,
            y: Config.windowMargin,
            width: windowWidth,
            height: windowHeight
        )

        clockWindow = initWindow(rect: rect, timeLabel: timeLabel, dateLabel: dateLabel)
        hideWindow()
    }
}

let app = NSApplication.shared
let clock = Clock()
app.delegate = clock
app.setActivationPolicy(.accessory)
app.run()
