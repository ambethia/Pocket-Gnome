waxClass{"PGCombat", Plugin}

function ePluginLoaded(self)

	puts("Hello from PGCombat")
	
end

function desc(self)

	return "fucking pwned"

end

function author(self)

	return "your mom"
		
end

function ePluginLoadConfig(self) 
	wax.struct.create("NSRect", "ffff", "x", "y", "width", "height")
    local frame = NSRect(200.0, 200.0, 200.0, 150.0)
    local panel = NSPanel:initWithContentRect_styleMask_backing_defer(frame, 8211, 2, 0)
    local label = NSTextField:initWithFrame(NSRect(0, 110, 200, 40))
    label:setStringValue("Ololol")
    label:setEditable(false)
    label:setDrawsBackground(false)
    --label:setBackgroundColor(NSColor:clearColor())
    label:setBezeled(false)
    label:setAlignment(2)
    label:setFont(NSFont:boldSystemFontOfSize(16.0))
    label:setTextColor(NSColor:whiteColor())
    local contentView = NSView:initWithFrame(frame)
    panel:setContentView(contentView)
    contentView:addSubview(label)
    panel:makeKeyAndOrderFront(NSApplication:sharedApplication())
end
