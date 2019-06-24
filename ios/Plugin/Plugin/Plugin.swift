import Foundation
import Capacitor
import FBSDKCoreKit
import FBSDKLoginKit

@objc(FacebookLogin)
public class FacebookLogin: CAPPlugin {
    private let loginManager = LoginManager()
    
    private let dateFormatter = ISO8601DateFormatter()
  
    private var granted: [String]?;
    private var denied: [String]?;
    
    override public func load() {
        if #available(iOS 11, *) {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
        }
        
    }

    private func dateToJS(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @objc func login(_ call: CAPPluginCall) {
        guard let permissions = call.getArray("permissions", String.self) else {
            call.error("Missing permissions argument")
            return;
        }
        // print("[CapacitorFacebook] 🙏 request permissions " + permissions.debugDescription);
        
        DispatchQueue.main.async {
            
            self.loginManager.logIn(permissions: permissions, from: self.bridge.viewController, handler: { (loginResult: LoginManagerLoginResult?, error: Error?) in
            
                if (loginResult != nil) {
                    
                    if (loginResult?.isCancelled ?? false) {
                    // print("[CapacitorFacebook] ❌ cancelled");
                    call.error("cancelled");
                    return;
                    }
                    
                    self.granted = loginResult?.grantedPermissions.map({ (s: String) -> String in return s });
                    self.denied = loginResult?.declinedPermissions.map({ (s: String) -> String in return s });  // !! deNied not deCLined (so as to keep consistent with plugin method signature)
                    // print("[CapacitorFacebook] 👍 granted " + self.granted.debugDescription);
                    // print("[CapacitorFacebook] 👎 denied " + self.denied.debugDescription);
                    
                    self.getCurrentAccessToken(call);
                    
                } else {
                    // print("[CapacitorFacebook] ❌ got error " + error.debugDescription);
                    call.error(error.debugDescription);
                }

            });

        }
    }
    
    @objc func logout(_ call: CAPPluginCall) {
      
        loginManager.logOut()
      
        self.granted = nil;
        self.denied = nil;
        
        call.success()
    }
    
    private func accessTokenToJson(_ accessToken: AccessToken) -> [String: Any?] {
        return [
            "applicationId": accessToken.appID, // Id not ID so as to keep the same plugin signature
            "expires": dateToJS(accessToken.expirationDate),
            "lastRefresh": dateToJS(accessToken.refreshDate),
            "token": accessToken.tokenString,
            "userId": accessToken.userID // Id not ID so as to keep the same plugin signature
        ];
    }
    
  @objc func getCurrentAccessToken(_ call: CAPPluginCall) {
    
        var data: PluginResultData = [:];
    
        if (self.granted != nil) {
          data["recentlyGrantedPermissions"] = self.granted!;
        }
    
        if (self.denied != nil) {
          data["recentlyDeniedPermissions"] = self.denied!;
        }
    
        let accessToken = AccessToken.current;
    
        if (accessToken != nil) {
          data["accessToken"] = self.accessTokenToJson(accessToken!);
        }
        
        call.success(data);
    }
}
