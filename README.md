# iOS-SIP.js
This is everything you need to get SIP.js running on iOS. Background incoming calls, Transfer, Hold, Mute, all working. 

NOTE: SIP.js Video is not supported by this plugin at this time. Only Audio works.

# Installation

 - Add the plugin to your Cordova project. (cordova plugin add https://github.com/BetterVoice/iOS-SIP.js.git)
 - Follow the instructions printed to your shell console after the plugin installation finishes. You will need to add the WebRTC libs to your project. We provide precompiled libs in the instructions: http://s3.bettervoice.com/webrtclibs/webrtc-ios-unified.a (supports x86+arm)
 - Configure your SIP.js project to use the media handler provided by this plugin, instead of the default SIP.js media handler.
 
# Example Usage

You need to configure your SIP.js User Agent to use the custom media handler provided by this plugin when the environment is iOS + Cordova. See below for an example.

```javascript
        window.ua = new SIP.UA({
          traceSip: false,
          log: {
            builtinEnabled: false
          },
          displayName: $scope.session.account.name,
          uri: $scope.sipUsername,
          rel100: 'supported',
          authorizationUser: $scope.sipUsername,
          password: $scope.sipPassword,
          wsServers: 'ws://'+$scope.sipDomain+':5066',
          register: true,
          mediaHandlerFactory: function defaultFactory (session, options) {        
            if (window.cordova && device.platform === 'iOS') {
              window.console.log('Using Custom Cordova Media Handler');
              PhoneRTCMediaHandler = cordova.require('com.bettervoice.phonertc.mediahandler')(SIP);
              return new PhoneRTCMediaHandler(session, options);
            }
            else {
              window.console.log('Using Normal SIP.js Media Handler');
              return new SIP.WebRTC.MediaHandler.defaultFactory(session, options);
            }        
          },
          media: {
            constraints: {
              audio: true,
              video: false
            },
            render: {
              remote: {
                audio: document.createElement('audio')
              }
            }
          }
        });
```
