{ pkgs, ... }:

with pkgs; [
  # Digital Audio Workstations (DAWs)
  ardour   # Professional DAW
  lmms     # Linux MultiMedia Studio
  qtractor # Audio/MIDI sequencer
  
  # Synthesizers
  helm         # Software synthesizer
  zynaddsubfx  # Software synthesizer
  
  # Audio utilities
  carla      # Audio plugin host
  qjackctl   # JACK audio connection kit control
  alsa-utils # ALSA utilities
  
  # MIDI
  fluidsynth  # MIDI synthesizer (for playing piano)
  
  # Soundfonts
  soundfont-fluid        # Fluid soundfont
  soundfont-generaluser  # GeneralUser soundfont
  soundfont-ydp-grand    # YDP Grand Piano soundfont
]

