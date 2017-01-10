
(
Server.default=s=Server.local;
o=s.options;
o.memSize = 2.pow(18);
o.memSize.postln;
s.boot;

MIDIClient.init;
MIDIIn.connectAll;
)
(
MIDIdef.noteOn(\noteOn, {
	arg vel, nn , chan, src;
	[nn,vel].postln;
	~notes[nn] = Synth.before(~effect,
		\warmpad,
		[
			\freq, nn,
			\amp, vel.linexp(1,127,0.01,0.4),
			\gate, 1,
			\effectBus, b.index
		]
	);
});

MIDIdef.noteOff(\noteOff, {
	arg vel, nn, chan, src;
	~notes[nn].set(\gate,0);
	~notes[nn]=nil;
});

~notes = Array.newClear(128);

SynthDef(\warmpad,{|effectBus= 0 freq = 440 amp = 0.1 gate=1 lforate = 4.85 lfowidth= 0.5 cutoff= 2000 rq=0.5 pan = 0.0|

	var signal, filter, env;

	signal = GVerb.ar(
		LFNoise2.ar(10,0.3)
		+ SinOscFB.ar(freq.midicps*LFNoise0.ar(100,0.01,1),0.3,0.3*SinOsc.ar(1,0,0.02,1))
		* SinOscFB.ar(freq.midicps*LFNoise0.ar(100,0.01,1),0.5,0.3*SinOsc.ar(1,pi/2,0.02,1))
	,243,1,0.1,0.34,15,(-3).dbamp,(-11).dbamp,(-9).dbamp)!2;
	env = EnvGen.ar(Env.adsr(4,1.0,0.8,4.0),gate,doneAction:2);

	Out.ar(effectBus,Pan2.ar(Mix(signal)*env*amp,pan));

}).add;



//chorus and compression
SynthDef(\choruscompresseffect, {|out =0 gate= 1 inBus=1|
	var source = In.ar(inBus,2);
	var chorus;
	var env = Linen.kr(gate, 0.1, 1, 0.1, 2);


	chorus= Splay.ar(Array.fill(4,{
		var maxdelaytime= rrand(0.005,0.02);

		DelayC.ar(source, maxdelaytime,LFNoise1.kr(Rand(0.1,0.6),0.25*maxdelaytime,0.75*maxdelaytime) )
	}));

	chorus = Limiter.ar(source,1);

	XOut.ar(out,env,chorus);

}).add;

b = Bus.audio(s,2);

~effect = Synth.new(\choruscompresseffect, [\inBus, b.index]);
)