{ pkgs, ... }:

with pkgs; [
  # Python with packages
  (python3.withPackages (ps: with ps; [
    pip
    virtualenv
    flask
    requests
    pyperclip
    textual
    pypresence
  ]))
]

