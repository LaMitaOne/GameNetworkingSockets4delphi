# GameNetworkingSockets4delphi
A dynamic Delphi wrapper for Valve's Open-Source GameNetworkingSockets library. This wrapper allows you to use the C++ Flat API in Delphi x64 projects without static linking issues.
    
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/LaMitaOne/GameNetworkingSockets4delphi)    
       
Features     
    
    Fully dynamic loading (no crashes if a function is missing in the DLL)
    Automatic fallback for C++ name mangling (e.g., @4 decorators)
    Implements the v009 Interface for Sockets and Utils
    Ready to use UI example for Server/Client testing
     
Usage     
     
    Put all 4 dlls  in your executable folder.
    Add GameNetworkingSockets.pas to your project uses clause.
    Call LoadGameNetworkingSocketsDLL to load the library dynamically.
    Initialize the system with GameNetworkingSockets_Init(nil, @ErrMsg).
    Grab the interface via SteamAPI_SteamNetworkingSockets_v009.
     
Check out Unit1.pas for a complete working example of a Server listening, a Client connecting, sending messages, and checking the ping.     
