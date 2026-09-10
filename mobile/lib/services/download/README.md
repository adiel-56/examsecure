Dossier réservé aux services spécifiques à ce domaine (ex: wrapper autour
d'un SDK tiers comme le widget KkiaPay natif, ou d'un plugin de
notifications push). Actuellement, les appels HTTP génériques sont
centralisés dans /lib/repositories et /lib/core/network. Ajoutez ici un
service dédié dès qu'une logique non-HTTP (SDK natif, chiffrement
spécifique à un flux, cache local complexe) devient nécessaire.
