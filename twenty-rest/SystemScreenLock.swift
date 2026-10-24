import Foundation

/// Triggers the system lock screen (same end state as Control Center / Ctrl-Cmd-Q).
enum SystemScreenLock {
    static func lock() {
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        guard let handle = dlopen(path, RTLD_LAZY) else { return }
        defer { dlclose(handle) }

        typealias LockFn = @convention(c) () -> Void
        guard let symbol = dlsym(handle, "SACLockScreenImmediate") else { return }
        let lockScreen = unsafeBitCast(symbol, to: LockFn.self)
        lockScreen()
    }
}
