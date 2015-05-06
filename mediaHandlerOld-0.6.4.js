/**
 * @fileoverview OldMediaHandler
 */

/**
 * MediaHandler
 * @class PeerConnection helper Class.
 * @param {SIP.Session} session
 * @param {Object} [options]
 */
//module.exports = function(SIP) {
	/**
	 * Implements the PhoneRTC media handler constructor.
	 */
	var PhoneRTCMediaHandlerLegacy = function(session, options) {
		// Create a logger.
  	window.console.log('Loading the PhoneRTC 2.0 Media Handler.');

  	// Finish initialization.
  	this.phonertc = {
  		/*
  		 * Possible states are:
  		 * - disconnected
  		 * - connected
       * - holding
  		 * - muted
       */
  		'state': 'disconnected'
  	};
	}

	PhoneRTCMediaHandlerLegacy.prototype = Object.create(SIP.MediaHandler.prototype, {
		/**
		 * render() is called by sip.js so it must be defined.
		 */
		render: {writable: true, value: function render() { }},

  	isReady: {writable: true, value: function isReady() { return true; }},

  	close: {writable: true, value: function close() {
  		var state = this.phonertc.state;
  		if(state !== 'disconnected') {
  			this.phonertc.session.close();
  			this.phonertc.session = null;
  			// Update our state.
  			this.phonertc.state = 'disconnected';
  		}
  	}},

  	getDescription: {writable: true, value: function getDescription(onSuccess, onFailure, mediaHint) {
      var phonertc = this.phonertc;
      var isInitiator = !phonertc.role || phonertc.role === 'caller';
  		if(isInitiator && phonertc.state === 'disconnected') {
        this.startSession(null, onSuccess, onFailure);
      } else {
        if(phonertc.state === 'holding') {
          onSuccess(phonertc.sdp.replace(/a=sendrecv\r\n/g, 'a=sendonly\r\n'));
        } else {
          onSuccess(phonertc.sdp);
          if(phonertc.state === 'disconnected') {
            phonertc.state = 'connected';
          }
        }
      }
  	}},

  	setDescription: {writable: true, value: function setDescription(sdp, onSuccess, onFailure) {
  		var phonertc = this.phonertc;
      var isNewCall = !phonertc.role;
  		if(isNewCall) {
        this.startSession(sdp, onSuccess, onFailure);
      }
  		var session = phonertc.session;
  		if((phonertc.role === 'caller' && phonertc.state === 'disconnected')) {
        session.receive({'type': 'answer', 'sdp': sdp});
        onSuccess();
        if(phonertc.state === 'disconnected') {
          phonertc.state = 'connected';
        }
  		} else {
        onSuccess();
      }
  	}},

  	isMuted: {writable: true, value: function isMuted() {
  	  return {
  	    audio: this.phonertc.state === 'muted' ||
               this.phonertc.state === 'holding',
  	    video: true
  	  };
  	}},

  	mute: {writable: true, value: function mute(options) {
      var phonertc = this.phonertc;
  		var state = phonertc.state;
  		if(state === 'connected') {
  			phonertc.session.mute();
  			phonertc.state = 'muted';
  		}
  	}},

  	unmute: {writable: true, value: function unmute(options) {
      var phonertc = this.phonertc;
  		var state = phonertc.state;
  		if(state === 'muted') {
  			phonertc.session.unmute();
  			phonertc.state = 'connected';
  		}
  	}},

    hold: {writable: true, value: function hold () {
      var phonertc = this.phonertc;
      var state = phonertc.state;
      if(state === 'connected') {
        phonertc.session.mute();
        phonertc.state = 'holding';
      }
    }},

    unhold: {writable: true, value: function unhold () {
      var phonertc = this.phonertc;
      var state = phonertc.state;
      if(state === 'holding') {
        phonertc.session.unmute();
        phonertc.state = 'connected';
      }
    }},

  	// Local Methods.
  	startSession: {writable: true, value: function startSession(sdp, onSuccess, onFailure) {
      var phonertc = this.phonertc;
  		phonertc.role = sdp === null ? 'caller' : 'callee';
      // Unfortunately, there is no message to let us know
      // that PhoneRTC has finished gathering ice candidates.
      // We use a watchdog to make sure all the ICE candidates
      // are allocated before returning the SDP.
      var watchdog = null;
      phonertc.session = new cordova.plugins.phonertc.Session({
        isInitiator: phonertc.role === 'caller'
      });
      phonertc.session.on('sendMessage', function (data) {
        if(data.type === 'offer' || data.type === 'answer') {
          phonertc.sdp = data.sdp;
          if(data.type === 'answer') {
            if(onSuccess) { onSuccess(); }
          }
        } else if(data.type === 'candidate') {
          // If we receive another candidate we stop
          // the watchdog and restart it again later.
          if(watchdog !== null) {
            clearTimeout(watchdog);
          }
          // Append the candidate to the SDP.
          var candidate = "a=" + data.candidate + "\r\n";
          if(data.id === 'audio') {
            phonertc.sdp += candidate;
          }
          // Start the watchdog.
          watchdog = setTimeout(function() {
            if(onSuccess) {
              onSuccess(phonertc.sdp);
            }
          }, 500);
        }
      });
      // If we received a session description pass it on to the
      // PhoneRTC plugin.
      if(phonertc.role === 'callee') {
        phonertc.session.receive({'type': 'offer', 'sdp': sdp});
      }
      // Start the media.
      phonertc.session.initialize();
  	}}
	});

	// Return the PhoneRTC media handler implementation.
	//return PhoneRTCMediaHandlerLegacy;
//};
