import Orion
import insulationC
import QuartzCore

// MARK: - 120Hz 刷新率锁
//
// 原理：ProMotion 的自适应降帧，本质是系统在 idle / 省电场景下调低
// CADisplayLink.minimumFrameRate（压到 10/60）。这里把 setter clamp 住：
// 开关开启时，任何进程（backboardd / SpringBoard / 各 app）想把 min 压低于 120，
// 都被我们强行改回 120，面板刷新率因此保持 120Hz。
//
// 同时覆盖 iOS15+ 的 preferredFrameRateRange 新 API。
// 非 ProMotion 机型（最大 60Hz）下强制 120 无效也不会崩溃（上限于面板能力）。

class CADisplayLinkRefreshHook: ClassHook<CADisplayLink> {

  // 旧 API：minimumFrameRate / maximumFrameRate 属性 setter
  func setMinimumFrameRate(_ rate: Float) {
    if RefreshLock.shared.isEnabled {
      orig.setMinimumFrameRate(120.0);
    } else {
      orig.setMinimumFrameRate(rate);
    }
  }

  func setMaximumFrameRate(_ rate: Float) {
    if RefreshLock.shared.isEnabled {
      // max 上限锁到 120，避免未来 >120 面板被顶上去
      orig.setMaximumFrameRate(120.0);
    } else {
      orig.setMaximumFrameRate(rate);
    }
  }

  // iOS15+ 新 API：preferredFrameRateRange
  func setPreferredFrameRateRange(_ range: CADisplayPreferredFrameRateRange) {
    if RefreshLock.shared.isEnabled {
      orig.setPreferredFrameRateRange(
        CADisplayPreferredFrameRateRange(minimum: 120, maximum: 120)
      );
    } else {
      orig.setPreferredFrameRateRange(range);
    }
  }
}

// MARK: - 开关状态（缓存 + Darwin 通知热更新）

class RefreshLock {
  private init() { self.reload(); }
  static let shared = RefreshLock();

  private(set) var isEnabled: Bool = false;

  /// 从设置 plist 重新读取 lock120hz
  func reload() {
    let prefs = IFileManager.getPlistContent(
      withPath: insulationC.rootlessPath("/var/mobile/Library/Preferences/com.be-huge.insulation-prefs.plist")
    );
    self.isEnabled = (prefs["lock120hz"] as? Bool) ?? false;
  }
}

// 加载时读一次 + 监听设置页切换，实现热更新
class RefreshLockInit: Tweak {
  required init() {
    _ = RefreshLock.shared;
    let center = CFNotificationCenterGetDarwinNotifyCenter();
    let name = "com.be-huge.insulation-refreshLockChanged" as CFString;
    let observer = UnsafeMutableRawPointer(Unmanaged.passRetained(RefreshLock.shared).toOpaque());
    CFNotificationCenterAddObserver(center, observer, { _, _, _, _, _ in
      RefreshLock.shared.reload();
    }, name, nil, .deliverImmediately);
  }
}
