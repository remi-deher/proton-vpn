.pragma library

// Display-time translation. The service keeps English strings internally (they
// are compared, stored in state.json, and matched against CLI output), and the
// views pass them through t() just before drawing. Unknown text is returned
// unchanged, so a missing entry degrades to English and never to a blank.
//
// Add a language: add a table under TABLES and its pattern list under PATTERNS.

var FR = {
  // status
  "Not installed": "Non installé",
  "Protected": "Protégé",
  "Not protected": "Non protégé",
  "Connecting…": "Connexion…",
  "Checking…": "Vérification…",
  "Signed out": "Déconnecté du compte",
  "Disconnecting…": "Déconnexion…",
  "Signing out…": "Fermeture de session…",
  "Loading…": "Chargement…",
  "Turning on…": "Activation…",
  "Turning off…": "Désactivation…",
  // quick connect and places
  "Fastest": "Le plus rapide",
  "Random": "Aléatoire",
  "P2P": "P2P",
  "Secure Core": "Secure Core",
  "Tor": "Tor",
  "Fastest P2P": "P2P le plus rapide",
  "Fastest Secure Core": "Secure Core le plus rapide",
  "Fastest Tor": "Tor le plus rapide",
  "Fastest server": "Serveur le plus rapide",
  "Best server for your location": "Meilleur serveur pour votre position",
  "Proton's best pick for your location": "Le meilleur choix de Proton pour votre position",
  "Any available server": "N'importe quel serveur disponible",
  "Fastest server that allows file sharing": "Serveur le plus rapide autorisant le partage de fichiers",
  "Optimized for file sharing": "Optimisé pour le partage de fichiers",
  "Two hops through Switzerland, Iceland or Sweden": "Deux sauts via la Suisse, l'Islande ou la Suède",
  "VPN first, then the Tor network": "VPN d'abord, puis le réseau Tor",
  "Via P2P": "Via P2P",
  "Via Secure Core": "Via Secure Core",
  "Via Tor": "Via Tor",
  "Reconnecting to fastest…": "Reconnexion au plus rapide…",
  "Connecting to fastest…": "Connexion au plus rapide…",
  "Connecting to a random server…": "Connexion à un serveur aléatoire…",
  "Connecting via Secure Core…": "Connexion via Secure Core…",
  "Connecting via Tor…": "Connexion via Tor…",
  // sections
  "Quick connect": "Connexion rapide",
  "Profiles": "Profils",
  "Recent": "Récents",
  "Countries": "Pays",
  "Cities": "Villes",
  "Protection": "Protection",
  "Account": "Compte",
  // countries / cities
  "Find a country": "Chercher un pays",
  "All countries": "Tous les pays",
  "Loading": "Chargement",
  "1 server": "1 serveur",
  // protections
  "Kill Switch": "Kill Switch",
  "Block traffic if the tunnel drops": "Bloque le trafic si le tunnel tombe",
  "NetShield": "NetShield",
  "Block malware, ads and trackers": "Bloque malwares, pubs et traqueurs",
  "Port forwarding": "Redirection de port",
  "Open an inbound port": "Ouvre un port entrant",
  "Always On": "Toujours actif",
  "Reconnect automatically": "Se reconnecte automatiquement",
  "Split tunneling": "Tunnel scindé",
  "Mode": "Mode",
  "Apps": "Applications",
  "Exclude: chosen apps skip the VPN": "Exclure : les apps choisies évitent le VPN",
  "Include: only chosen apps use the VPN": "Inclure : seules les apps choisies utilisent le VPN",
  "Keep chosen apps off the VPN": "Garder des apps hors du VPN",
  "No apps chosen yet": "Aucune app choisie",
  "Sign in and connect once first": "Connectez-vous d'abord une fois",
  "Turn the Kill Switch off to use this": "Désactivez le Kill Switch pour l'utiliser",
  "Could not read Proton's settings": "Impossible de lire les réglages de Proton",
  "Could not save Proton's settings": "Impossible d'enregistrer les réglages de Proton",
  "Restart each chosen app after connecting, or it keeps using the tunnel it started on.":
    "Redémarrez chaque app choisie après la connexion, sinon elle garde le tunnel de son démarrage.",
  "Search apps…": "Chercher une app…",
  "No apps found": "Aucune app trouvée",
  "None chosen": "Aucune",
  // account / install
  "Sign in": "Se connecter",
  "Sign out": "Se déconnecter",
  "Install Proton VPN CLI": "Installer Proton VPN CLI",
  "Installing…": "Installation…",
  "Proton username (not your email)": "Nom d'utilisateur Proton (pas l'e-mail)",
  "The Proton VPN command line client isn't installed. Installing it asks for your password through the system prompt.":
    "Le client en ligne de commande Proton VPN n'est pas installé. L'installation demande votre mot de passe via l'invite système.",
  "The Proton VPN desktop app is installed. It can't run alongside the CLI: quit it before connecting.":
    "L'application Proton VPN est installée. Elle ne peut pas tourner avec la CLI : quittez-la avant de vous connecter.",
  "Sign in with your Proton account. A terminal opens for your password and 2FA code, then closes.":
    "Connectez-vous avec votre compte Proton. Un terminal s'ouvre pour le mot de passe et le code 2FA, puis se ferme.",
  "Usernames can only contain letters, numbers and . _ + @ -":
    "Un nom d'utilisateur ne peut contenir que lettres, chiffres et . _ + @ -",
  // profiles
  "New profile": "Nouveau profil",
  "Edit profile": "Modifier le profil",
  "Name a place, pick a colour, get there in one click": "Nommez un lieu, choisissez une couleur, rejoignez-le en un clic",
  "Name, like Home or Work": "Nom, par ex. Maison ou Travail",
  "Colour": "Couleur",
  "Where": "Où",
  "Feature": "Option",
  "None": "Aucune",
  "Save": "Enregistrer",
  "Cancel": "Annuler",
  "Delete": "Supprimer",
  // errors / toasts
  "Proton VPN is busy, try again in a moment": "Proton VPN est occupé, réessayez dans un instant",
  "Requires a Proton VPN Plus plan": "Nécessite un abonnement Proton VPN Plus",
  "Needs Proton VPN Plus. Fastest picks a Free server for you.": "Nécessite Proton VPN Plus. « Le plus rapide » choisit un serveur gratuit pour vous.",
  "Setting failed": "Échec du réglage",
  "Connect failed": "Échec de la connexion",
  "Command failed": "Échec de la commande",
  "VPN Connected": "VPN connecté",
  "VPN Disconnected": "VPN déconnecté",
  "You're no longer protected.": "Vous n'êtes plus protégé.",
  // settings (manifest)
  "Server": "Serveur",
  "Location": "Lieu",
  "Load": "Charge",
  "Protocol": "Protocole",
  "Forwarded port": "Port redirigé",
  "Signed in as": "Connecté en tant que",
  "Plan": "Offre"
}

// [regex, function(match) -> string]
var FR_PATTERNS = [
  [/^Connecting to (.+)…$/, function(m) { return "Connexion à " + t(m[1], "fr") + "…" }],
  [/^Reconnecting to (.+)…$/, function(m) { return "Reconnexion à " + t(m[1], "fr") + "…" }],
  [/^Fastest in (.+)$/, function(m) { return "Le plus rapide en " + m[1] }],
  [/^Only 1 app uses the VPN$/, function() { return "Une seule app utilise le VPN" }],
  [/^Only (\d+) apps use the VPN$/, function(m) { return "Seules " + m[1] + " apps utilisent le VPN" }],
  [/^1 app skips the VPN$/, function() { return "1 app évite le VPN" }],
  [/^(\d+) apps skip the VPN$/, function(m) { return m[1] + " apps évitent le VPN" }],
  [/^(\d+) servers$/, function(m) { return m[1] + " serveurs" }],
  [/^Forwarded port (.+)$/, function(m) { return "Port redirigé " + m[1] }],
  [/^Cities · (.+)$/, function(m) { return "Villes · " + m[1] }],
  [/^VPN (Connected|Disconnected) .*$/, function(m) { return m[1] === "Connected" ? "VPN connecté" : "VPN déconnecté" }]
]

// "auto" follows the system locale; anything unknown is English.
function resolve(setting, localeName) {
  var s = String(setting || "auto")
  if (s === "auto") s = String(localeName || "").toLowerCase().indexOf("fr") === 0 ? "fr" : "en"
  return s === "fr" ? "fr" : "en"
}

function t(text, lang) {
  if (lang !== "fr") return text
  var s = String(text === undefined || text === null ? "" : text)
  if (FR.hasOwnProperty(s)) return FR[s]
  for (var i = 0; i < FR_PATTERNS.length; i++) {
    var m = s.match(FR_PATTERNS[i][0])
    if (m) return FR_PATTERNS[i][1](m)
  }
  return s
}
