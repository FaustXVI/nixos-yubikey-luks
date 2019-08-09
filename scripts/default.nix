{ stdenv, openssl, cryptsetup,pbkdf2Sha512, yubikey-personalization }:

stdenv.mkDerivation rec {
  name = "encryption-script";
  version = "latest";
  buildInputs = [
      cryptsetup
      openssl
      pbkdf2Sha512
      yubikey-personalization
];  
    
  src = ./.;
  installPhase = ''
    mkdir -p $out/bin
    cp $src/encrypt.sh $out/bin
  '';
}
