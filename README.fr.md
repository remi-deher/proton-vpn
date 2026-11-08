# Proton VPN pour Ryoku

Proton VPN dans la barre Ryoku (niri). Portage du plugin
[OmaProton VPN](https://github.com/grichard99/omaproton-vpn) de grichard99
(écrit pour Omarchy) vers le système de plugins Ryoku. Il pilote la CLI
officielle `protonvpn` ; aucun identifiant n'est stocké par le plugin.

## Installation

```bash
ryoku plugin add ~/GitHub/ryoku-proton-vpn --bar --yes
```

Cliquez sur la marque Proton dans la barre : le panneau installe la CLI
(`proton-vpn-cli`) puis vous connecte.

## Utilisation

| Action | Effet |
| --- | --- |
| Clic gauche | Ouvre le panneau |
| Clic droit | Connexion au serveur le plus rapide, ou déconnexion |
| Clic milieu | Force un rafraîchissement |

Le panneau contient la carte du monde (la ville connectée est allumée),
l'interrupteur, le trafic en direct, la connexion rapide (le plus rapide,
aléatoire, P2P, Secure Core, Tor), les profils nommés, les récents, la
navigation pays/villes, et les protections : Kill Switch, NetShield,
redirection de port, Toujours actif, tunnel scindé.

## Connexion

Un terminal s'ouvre pour le mot de passe et le code 2FA. En cas d'échec il
reste ouvert pour lire le message de la CLI. La CLI 1.0.5 attend une clé de
sécurité par défaut : le plugin passe `--totp` (code d'application
d'authentification), sauf si vous désactivez ce réglage dans les paramètres.

Utilisez votre **nom d'utilisateur** Proton, pas votre e-mail : la CLI refuse
l'e-mail avec « Authentication failed ».

## Langue

Suit la langue du système (français ou anglais). Réglage « Language » pour la
forcer.

## Clavier

Haut/Bas parcourent les lignes, Entrée ou Espace active, Gauche/Droite
changent une valeur, `/` ouvre la recherche de pays, `e` modifie un profil,
Échap quitte un champ.

## Ce qu'il exécute, lit et écrit

- **Exécute** : `protonvpn`, `nmcli`, `python3` (aides dans `bin/`), `cat`
  sur `/sys/class/net`, `busctl` (notifications), `ryoku-app terminal`,
  `flock`.
- **Privilégié** : uniquement au clic sur « Installer Proton VPN CLI » :
  `pkexec pacman -S --needed --noconfirm proton-vpn-cli`.
- **Lit** : `~/.cache/Proton/VPN/serverlist.json` et
  `~/.config/Proton/VPN/settings.json`.
- **Écrit** : son état dans `$XDG_STATE_HOME/ryoku/plugins/proton-vpn`, et le
  `settings.json` de Proton pour le tunnel scindé.
- **Réseau** : aucun de son côté. La carte est dessinée hors ligne.

## Crédits

Dérivé de [OmaProton VPN](https://github.com/grichard99/omaproton-vpn) (MIT,
© grichard99). Contour des terres : Natural Earth (domaine public). Marque
Proton : Simple Icons (CC0). Sans lien avec Proton AG.
