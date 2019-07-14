@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // some code
        
        registPush()
        checkPush(options: launchOptions)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 앱이 active가 되면 badge와 온 푸시들을 모두 Clear 합니다.
        clearPush()
    }
}

// MARK: - Push Process

extension AppDelegate {
    private func registPush() {
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            current.delegate = self
            current.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                DispatchQueue.main.async {
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    } else {
                        // Fail case. 수락을 안하는 케이스
                    }
                }
            }
        } else { // iOS10 미만
            let settings = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    private checkPush(options: [UIApplication.LaunchOptionsKey: Any]?) {
        guard let payload = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] else { return }
        processPayload(payload)
    }
    
    private clearPush() {
        UIApplication.shared.applicationIconBadgeNumber = 1
        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    private processPayload(_ payload: [AnyHashable: Any], background: Bool) {
        // Push 처리
    }
}

// MARK: - Push 등록 관련

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Log.debug(token)
        // Token이 발생하여서 등록처리 필요함. Push 관리하는 서버로 token 전송
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Token등록시 에러 발생
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        // iOS10 미만에서 호출됨
        UIApplication.shared.registerForRemoteNotifications()
    }
}

// MARK: - Push 수신 처리

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 구동되어 있으면 호출됨
        processPayload(notification.request.content.userInfo, background: false)
        completionHandler(.alert) // 푸시가 오면 어떻게 표현이 되는지에 대해서 정의
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 앱이 백그라운드 상태면 호출됨
        processPayload(response.notification.request.content.userInfo, background: true)
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let state = application.applicationState
        switch state {
        case .background, .inactive:
            processPayload(userInfo, background: true)
        case .active:
            processPayload(userInfo, background: false)
        @unknown default:
            // 상태가 존재하지는 않음
            processPayload(userInfo, background: true)
        }
    }
}
