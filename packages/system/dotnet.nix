{ pkgs, ... }:

with pkgs; [
  # .NET development framework
  dotnet-sdk_8        # .NET SDK
  dotnet-runtime_8    # .NET runtime
  dotnet-aspnetcore_8 # ASP.NET Core runtime
]

