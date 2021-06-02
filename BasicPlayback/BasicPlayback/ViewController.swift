//
// Bitmovin Player iOS SDK
// Copyright (C) 2021, Bitmovin GmbH, All Rights Reserved
//
// This source code and its use and distribution, is subject to the terms
// and conditions of the applicable license agreement.
//

// MODIFIED - DANI - DEPARTMENT OF SOLUTIONS - BITMOVIN - 2021
// SEE THE README IN THE BASICPLAYBACK PROJECT ROOT DIRECTORY

import UIKit
import BitmovinPlayer

final class ViewController: UIViewController {
    var player: Player!
    var configProperties: Dictionary<String, Any>?

    deinit {
        player?.destroy()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .black

        // --- THIS IS AN UNBOUND VARIABLE IN THE OBJECTIVE-C SOURCE FRAGMENT
        let fairPlayDeviceId = "0"

        var licenseUrlString: String?
        var cerUrlString: String?
        if let configProperties = Bundle.main.infoDictionary {
            if let val = configProperties["licenseUrl"] as? String {
                licenseUrlString = val
            }
            else {print("**** ADD LICENSE URL TO INFO.PLIST")}
            if let val = configProperties["cerUrl"] as? String {
                cerUrlString = String(
                    format:"%@/v1.0?deviceId=%@", val, fairPlayDeviceId)
            }
            else {print("**** ADD CERTIFICATE URL TO INFO.PLIST")}
        }
        print("LICENCE URL CERT URL", licenseUrlString!, cerUrlString!)
        /*if (self.m_modle.isFairyPlay) {
                 NSURL* licenserUrl = [NSURL URLWithString:[NSString stringWithFormat:@"---LICENCE-URL---/v1.0?deviceId=%@",self.m_modle.fairPlayDeviceId]];*/
/*
 NSURL* cerUrl = [NSURL URLWithString:@"---CERT-URL---"];//[[NSBundle mainBundle] URLForResource:@"fairplay" withExtension:@"cer"];// */

        // Define needed resources
        guard let streamUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"),
              let posterUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/poster.jpg"),
              let licenseUrl = URL(string: licenseUrlString!),
              let cerUrl = URL(string: cerUrlString!)
        else {
            return
        }
              
     
        // Create player configuration
        let playerConfig = PlayerConfig()

        // Create player based on player config
        player = PlayerFactory.create(playerConfig: playerConfig)

        // Create player view and pass the player instance to it
        let playerView = PlayerView(player: player, frame: .zero)
        
        // Listen to player events
        player.add(listener: self)

        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerView.frame = view.bounds

        view.addSubview(playerView)
        view.bringSubviewToFront(playerView)

        // Create source config
        let sourceConfig = SourceConfig(url: streamUrl, type: .hls)
        
        
        let fconfig = FairplayConfig(
            license: licenseUrl, certificateURL: cerUrl)
        /*
          BMPFairplayConfig* fconfig = [[BMPFairplayConfig alloc] initWithLicenseUrl:licenserUrl certificateURL:cerUrl];
          */

        
        fconfig.prepareLicense = { (ckc: Data) -> Data in
            var json: Any?
            do {
                json = try JSONSerialization
                .jsonObject( with: ckc,
                             options: [.allowFragments])

            }
            catch { print(error) }

            if let dict = json as? [String:Any] {
                if let val = dict["ckc"] as? String {
                    print( "--- ckc value--- %s", val)
                    return Data(
                        base64Encoded: val,
                        options: .ignoreUnknownCharacters)!
                }
            }
            
            return Data(base64Encoded: "", options:
                            .ignoreUnknownCharacters)!
        }
        /*
         fconfig.prepareLicense = ^NSData * _Nonnull(NSData * _Nonnull ckc) {
             id json = [NSJSONSerialization JSONObjectWithData:ckc options:NSJSONReadingAllowFragments error:nil];
             NSDictionary* dict = json;
             NSString* data = dict[@"ckc"];
             return [[NSData alloc] initWithBase64EncodedString:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
         }; */

        fconfig.prepareMessage = { (spcData: Data, assedID: String) -> Data in
            let base64String = spcData
                .base64EncodedString(
                    options: [.lineLength64Characters])
            
            let uriEncodedMessage = base64String
                .addingPercentEncoding(
                    withAllowedCharacters: .alphanumerics)
            
            let message = String( format: "spc=%@", uriEncodedMessage!)

            return message.data(using: .nonLossyASCII)!
        }
        /*
        fconfig.prepareMessage = ^NSData * _Nonnull(NSData * _Nonnull spcData, NSString * _Nonnull assetID) {
            NSString* base64String = [spcData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];//spcData.base64Encoding;
            NSString* uriEncodedMessage = [base64String stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
            NSString* message = [NSString stringWithFormat:@"spc=%@",uriEncodedMessage];
            return [message dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
        };*/

        fconfig.prepareContentId = { (contentId: String) -> String in
            let newContentId = contentId
                .replacingOccurrences(
                    of:"skd://", with: "")
            return newContentId
        }
/*
  fconfig.prepareContentId = ^NSString * _Nonnull(NSString * _Nonnull contentId) {
      NSString* newContentId = [contentId stringByReplacingOccurrencesOfString:@"skd://" withString:@""];
      return newContentId;
  };
}
*/
        sourceConfig.drmConfig = fconfig
        
        // Set a poster image
        sourceConfig.posterSource = posterUrl
        player.load(sourceConfig: sourceConfig)
    }
}

extension ViewController: PlayerListener {
    func onEvent(_ event: Event, player: Player) {
        dump(event, name: "[Player Event]", maxDepth: 1)
    }
}
