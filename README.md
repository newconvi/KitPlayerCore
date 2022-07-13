# playerPublic
1.fix audio delay and Compatible with airplay2
playerPublic/mpv/audio/out/ao_audiounit.m
search render_cb_lpcm(void *ctx, AudioUnitRenderActionFlags *aflags,
                              const AudioTimeStamp *ts, UInt32 bus,
                              UInt32 frames, AudioBufferList *buffer_list)
add
AVAudioSession *instance = AVAudioSession.sharedInstance;
p->device_latency = [instance outputLatency] + [instance IOBufferDuration];

search [instance setCategory:AVAudioSessionCategoryPlayback error:nil];
replace
[instance setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback routeSharingPolicy:AVAudioSessionRouteSharingPolicyLongForm options:0 error:nil];
